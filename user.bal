import ballerina/http;
import ballerina/mime;
import ballerina/crypto;
import ballerina/sql;

const map<string> groupsId = {
    "Premium": "4fd91b80-0f54-4c33-a600-ccefe62f6a77",
    "Basic": "8dc035c0-7525-4ff4-8aee-a4771d81eada",
    "Free": "b28f3570-dd9e-4fa7-ba62-0e0ede387059"
};

type UserDB record {
    string 'UserID;
    string 'UserName;
    string|() 'OverviewLayout;
    string|() 'ComparisonLayout;
    string|() 'ForecastLayout;
    byte[]|() 'GH_AccessToken;
    byte[]|() 'ProfilePic;
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
    string 'Ownername;
    string 'Reponame;
    string 'UserID;
};

type UserRequest record {
    string ghUser;
    string repo;
    string userId;
};

function getUserGithubToken(string userId) returns string|error {
    do {
        byte[]|() ghToken = check dbClient->queryRow(`
                SELECT GH_AccessToken FROM Users WHERE UserID=${userId};`);
        if (ghToken == ()) {
            return error("no ghToken", message = "no ghToken for user", code = 400);
        }
        byte[] plainText = check crypto:decryptAesCbc(ghToken, encryptkey, initialVector);
        string accessToken = check string:fromBytes(plainText);
        return accessToken;
    } on fail var e {
        return e;
    }
}

function addRepo(UserRequest userRequest) returns sql:ExecutionResult|error {
    do {
        sql:ExecutionResult|sql:Error result = check dbClient->execute(`
                INSERT INTO Repositories (Ownername,Reponame,UserId)
                VALUES (${userRequest.ghUser}, ${userRequest.repo},${userRequest.userId});`);

        string ghToken = check getUserGithubToken(userRequest.userId);
        setRepositoryPerfomance(userRequest.ghUser, userRequest.repo, userRequest.userId, ghToken);
        return result;
    } on fail var e {
        return e;
    }

}

function removeRepo(string userId, string ownername, string reponame) returns sql:ExecutionResult|error {
    do {
        sql:ExecutionResult|sql:Error result = check dbClient->execute(`
                DELETE FROM Repositories WHERE UserId = ${userId} AND Reponame =${reponame} AND Ownername=${ownername};`);
        return result;
    } on fail var e {
        return e;
    }

}

function getUserAllRepos(string userId) returns json[]|error {
    json[] response = [];
    do {

        stream<RepositoriesInDB, sql:Error?> resultStream = dbClient->query(`SELECT * FROM Repositories WHERE UserID = ${userId}`);
        check from RepositoriesInDB repos in resultStream
            do {
                response.push({reponame: repos.'Reponame, ownername: repos.'Ownername});
            };
        check resultStream.close();
        return response;
    } on fail error e {
        return e;
    }

}

function authorizeToGithub(string code, string userId) returns json|error {
    http:Client github = check new ("https://github.com");
    string clientId = "9e50af7dd2997cde127a";
    string clientSecret = "201e65436456a06a98664c74611047bd8bdf16e5";
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
        return returnData;

    } on fail var err {
        return err;
    }

}

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

function getAllUserDetails() returns User[]|error {
    User[] response = [];

    do {

        stream<UserDB, sql:Error?> resultStream = dbClient->query(`SELECT * FROM Users`);
        check from UserDB user in resultStream
            do {
                User userById = check getUserById(user.'UserID);
                response.push(userById);
            };
        return response;
    } on fail error e {
        return e;
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

function changePic(string imageURL, string userId) returns sql:ExecutionResult|error {
    do {
        sql:ExecutionResult|sql:Error result = check dbClient->execute(`
	            UPDATE Users
                SET ProfilePic =${imageURL} 
	            WHERE UserID=${userId} ;`);
        return result;
    } on fail var e {
        return e;
    }

}

function changeUserLayout(string overviewlayout, string comparisonLayout, string forecastLayout, string userId) returns sql:ExecutionResult|error {
    do {
        sql:ExecutionResult|sql:Error result = check dbClient->execute(`
	            UPDATE Users
                SET OverviewLayout =${overviewlayout} ,ComparisonLayout=${comparisonLayout},ForecastLayout=${forecastLayout}
	            WHERE UserID=${userId} ;`);
        return result;
    } on fail var e {
        return e;
    }

}

function getPic(string userId) returns byte[]|error {
    byte[] response;

    do {
        response = check dbClient->queryRow(`
                SELECT ProfilePic FROM Users
	            WHERE UserID=${userId} ;`);
        return response;
    } on fail var e {
        return e;
    }

}

function getUserDetails(string userId) returns json|error {

    string accessToken = check getAuthToken("internal_user_mgt_view");

    map<string> asgardeoClientHeaders = {
        "Authorization": "Bearer " + accessToken
    };

    do {
        json data = check asgardeoClient->get("/t/tekno/scim2/Users/" + userId, asgardeoClientHeaders);
        return data;
    } on fail var e {
        return e;
    }
}

function getUserReportStatus(string userId) returns int|error {
    int response;
    do {
        response = check dbClient->queryRow(`
                SELECT isReportsEnable FROM Users
	            WHERE UserID=${userId} ;`);

        return response;
    } on fail var e {
        return e;
    }
}

function getUserLayout(string userId) returns json|error {
    json userLayouts;
    stream<UserDB, sql:Error?> resultStream;

    do {

        resultStream = dbClient->query(`SELECT * FROM Users WHERE UserID=${userId} `);
        check from UserDB row in resultStream
            do {
                userLayouts = {
                    OverviewLayout: row.'OverviewLayout,
                    ComparisonLayout: row.'ComparisonLayout,
                    ForecastLayout: row.'ForecastLayout
                };
                return userLayouts;
            };
    } on fail error e {
        return e;
    }
}

function setUserReportStatus(string userId, boolean isReportsEnable) returns sql:ExecutionResult|error {

    do {
        sql:ExecutionResult|sql:Error result = check dbClient->execute(`
	            UPDATE Users
                SET isReportsEnable =${isReportsEnable} 
	            WHERE UserID=${userId} ;`);
        return result;
    } on fail var e {
        return e;
    }
}

function changeUserDetails(string userId, string email, string number, string givenName, string familyName) returns json|error {

    string accessToken = check getAuthToken("internal_user_mgt_update");

    do {
        json data = check asgardeoClient->patch("/t/tekno/scim2/Users/" + userId, {
            "schemas": [
                "urn:ietf:params:scim:api:messages:2.0:PatchOp"
            ],
            "Operations": [
                {
                    "op": "replace",
                    "value": {
                        "emails": [email]
                    }
                },
                {
                    "op": "replace",
                    "value": {
                        "phoneNumbers": [{"type": "mobile", "value": number}]
                    }
                },
                {
                    "op": "replace",
                    "value": {
                        "name": [{"familyName": familyName, "givenName": givenName}]
                    }
                }
            ]
        },
        {
            "Authorization": "Bearer " + accessToken
        },
            mime:APPLICATION_JSON);
        return data;
    } on fail var e {
        return e;
    }
}

function getAllUsers() returns json[]|error {

    json[] users = [];
    stream<UserDB, sql:Error?> resultStream;

    do {
        resultStream = dbClient->query(`SELECT * FROM Users`);
        check from UserDB row in resultStream
            do {
                json user = check getUserDetails(row.'UserID);
                users.push(user);
            };
    } on fail error e {
        check resultStream.close();
        return e;
    }
    check resultStream.close();

    return users;

}
