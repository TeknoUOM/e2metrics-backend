import ballerina/http;
import ballerina/io;
import ballerina/mime;

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

type UserInDB record {
    string 'UserID?;
    string 'UserName?;
    string 'GH_AccessToken?;
};

type UserRequest record {
    string user;
    string repo;
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
        allowMethods: ["GET", "POST", "OPTIONS"]
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

            do {
                _ = check dbClient->execute(`
	            UPDATE Users
                SET GH_AccessToken = ${access_token}
	            WHERE UserID=${userId};`);
            }

            returnData = {
                res: response
            };

        } on fail var err {
            returnData = {
                "message": err.toString()
            };
        }
        return returnData;
    }

    resource function get getAllRepos(string userId) returns json|error|http:NotFound {
        json[] request;
        json response;
        Repository[] repos = [];
        Repository repo;
        UserInDB result;
        do {
            result = check dbClient->queryRow(`SELECT * FROM Users WHERE UserID = ${userId}`);
        } on fail error e {
            return e;
        }

        string GH_AccessToken = <string>result.GH_AccessToken;

        map<string> headers = {
            "Accept": "application/vnd.github.v3+json",
            "Authorization": "Bearer " + GH_AccessToken,
            "X-GitHub-Api-Version": "2022-11-28"
        };

        do {
            request = check github->get("/user/repos", headers);
            foreach json jsonRepo in request {
                repo = check jsonRepo.cloneWithType(Repository);
                repo = {
                    id: repo.'id,
                    name: repo.'name,
                    full_name: repo.'full_name,
                    description: repo?.'description,
                    owner: repo.'owner
                };
                repos.push(repo);
            }
            response = check repos.cloneWithType(json);
        } on fail var e {
            response = {
                "message": e.toString()
            };
        }
        return response;
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
                INSERT INTO Repositories (User,RepoName)
                VALUES (${userRequest.user}, ${userRequest.repo});`);
            response = {
                "message": "success"
            };
        } on fail var e {
            response = {
                "message": e.toString()
            };
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
