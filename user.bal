import ballerina/http;
import ballerina/io;
import ballerina/mime;
import ballerina/crypto;
import ballerina/sql;

const map<string> groupsId = {
    "Premium": "4fd91b80-0f54-4c33-a600-ccefe62f6a77",
    "Basic": "8dc035c0-7525-4ff4-8aee-a4771d81eada",
    "Free": "b28f3570-dd9e-4fa7-ba62-0e0ede387059"
};

type Owner record {
    string 'login?;
    decimal 'id?;
};

type Repository record {
    int 'id;
    string 'name;
    string 'full_name;
    string|() 'description?;
    Owner 'owner?;
};

type Group record {
    string 'display?;
    string 'value?;
};

type User record {
    string 'userName?;
    string[] 'emails?;
    Group[]|() 'groups?;
};

type RepositoriesInDB record {
    string 'user?;
    string 'RepoName?;
    string 'userId?;
};

type UserRequest record {
    string ghUser;
    string repo;
    string userId;
};

function getUserById(string userId) returns User|error {
    string accessToken = check getAuthToken("internal_user_mgt_view");

    do {
        json response = check asgardeoClient->get("/t/tekno/scim2/Users/" + userId, {
            "Authorization": "Bearer " + accessToken
        });

        User user = check response.cloneWithType(User);
        return user;
    } on fail var err {
        return err;
    }
}

function removeUserFromGroup(string userId, string groupName) returns json|error {
    string accessToken = check getAuthToken("internal_group_mgt_update");

    string url = "/t/tekno/scim2/Groups/" + groupsId.get(groupName);
    do {
        json response = check asgardeoClient->patch(url,
        {
            "schemas": [
                "urn:ietf:params:scim:api:messages:2.0:PatchOp"
            ],
            "Operations": [
                {
                    "op": "remove",
                    "path": "members[value eq " + userId + "]"
                }
            ]
        },
        {
            "Authorization": "Bearer " + accessToken
        },
            mime:APPLICATION_JSON
        );

        return response;
    } on fail var err {
        return err;
    }
}

function addUserToGroup(string userId, string groupName) returns json|error {
    User user = check getUserById(userId);
    string? username = user.'userName;

    string accessToken = check getAuthToken("internal_group_mgt_update");

    string url = "/t/tekno/scim2/Groups/" + groupsId.get(groupName);
    do {
        json response = check asgardeoClient->patch(url,
        {
            "schemas": [
                "urn:ietf:params:scim:api:messages:2.0:PatchOp"
            ],
            "Operations": [
                {
                    "op": "add",
                    "value": {
                        "members": [
                            {
                                "display": username,
                                "value": userId
                            }
                        ]
                    }
                }
            ]
        },
        {
            "Authorization": "Bearer " + accessToken
        },
            mime:APPLICATION_JSON
        );
        return response;
    } on fail var err {
        return err;
    }
}

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowCredentials: true,
        allowMethods: ["GET", "POST", "OPTIONS", "PUT"]
    }
}
service /user on httpListener {
    resource function post authorizeToGithub(@http:Payload map<json> reqBody) returns json|error {
        http:Client github = check new ("https://github.com");
        string clientId = "9e50af7dd2997cde127a";
        string clientSecret = "201e65436456a06a98664c74611047bd8bdf16e5";
        string code = check reqBody.code;
        string userId = check reqBody.userId;
        io:println(code);
        json returnData = {};
        do {
            json response = check github->post("/login/oauth/access_token",
            {
                client_id: clientId,
                client_secret: clientSecret,
                code: code
            },
            {
                Accept: mime:APPLICATION_JSON
            });

            string access_token = check response.access_token;
            byte[] data = access_token.toBytes();
            byte[] cipherText = check crypto:encryptAesCbc(data, encryptkey, initialVector);

            do {
                _ = check dbClient->execute(`
	            UPDATE Users
                SET GH_AccessToken = ${cipherText}
	            WHERE UserID=${userId};`);
            }

            returnData = {
                res: response
            };

        } on fail var err {
            return err;
        }
        return returnData;
    }

    resource function get getUserAllRepos(string userId) returns json|error|http:NotFound {
        json[] response = [];
        do {

            stream<RepositoriesInDB, sql:Error?> resultStream = dbClient->query(`SELECT * FROM Repositories WHERE userId = ${userId}`);

            // Iterating the returned table.
            check from RepositoriesInDB repos in resultStream
                do {
                    response.push(repos.'RepoName);
                };
            return response;
        } on fail error e {
            return e;
        }
    }

    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000"]
        }
    }
    resource function post addRepo(@http:Payload UserRequest userRequest) returns json|error {
        json response;
        do {
            _ = check dbClient->execute(`
                INSERT INTO Repositories (User,RepoName,userId)
                VALUES (${userRequest.ghUser}, ${userRequest.repo},${userRequest.userId});`);
            response = {
                "message": "success"
            };
        } on fail var e {
            return e;
        }
        return response;
    }
    resource function get getUserGithubToken(string userId) returns json|error {
        json response;
        do {
            byte[]|() ghToken = check dbClient->queryRow(`
                SELECT GH_AccessToken FROM Users WHERE UserID=${userId};`);
            if (ghToken == ()) {
                return error("no ghToken", message = "no ghToken for user", code = 400);
            }
            byte[] plainText = check crypto:decryptAesCbc(ghToken, encryptkey, initialVector);

            response = {
                "userId": userId,
                "ghToken": check string:fromBytes(plainText)
            };
        } on fail var e {
            return e;
        }
        return response;
    }

    resource function put changeUserGroup(string userId, string groupName) returns json|error {
        User user = check getUserById(userId);
        Group[] groups = user?.groups ?: [];
        if (user?.'groups != ()) {
            foreach Group group in groups {
                string tempGroupName = <string>group.'display;
                tempGroupName = tempGroupName.substring(8);
                _ = check removeUserFromGroup(userId, tempGroupName);
            }
        }
        json|error response = check addUserToGroup(userId, groupName);
        return response;
    }

    resource function post addUserToGroup(string userId, @http:Payload string groupName) returns json|error {
        json|error response = addUserToGroup(userId, groupName);
        return response;
    }

    resource function delete removeUserGroup(string userId, @http:Payload string groupName) returns json|error {
        json|error response = removeUserFromGroup(userId, groupName);
        return response;
    }
}
