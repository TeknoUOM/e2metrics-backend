import ballerina/http;
import ballerina/mime;

const map<string> groupsId = {
    "Premium": "4fd91b80-0f54-4c33-a600-ccefe62f6a77",
    "Basic": "8dc035c0-7525-4ff4-8aee-a4771d81eada",
    "Free": "b28f3570-dd9e-4fa7-ba62-0e0ede387059"
};

type Repository record {
    int 'id;
    string 'name;
    string 'full_name;
    string|() 'description?;
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
        allowOrigins: ["http://localhost:3000"]
    }
}
service /user on httpListener {

    resource function get getAllRepos() returns json|error {
        json[] request;
        json response;
        Repository[] repos = [];
        Repository repo;

        do {
            request = check github->get("/users/" + ownername + "/repos", headers);
            foreach json jsonRepo in request {
                repo = check jsonRepo.cloneWithType(Repository);
                repo = {
                    id: repo.'id,
                    name: repo.'name,
                    full_name: repo.'full_name,
                    description: repo?.'description
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
        json response = check addUserToGroup(userId, groupName);
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
