import ballerina/http;

type Repository record {
    int 'id;
    string 'name;
    string 'full_name;
    string|() 'description?;
};

type User record {
    string user;
    string repo;
};

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
    resource function post addRepo(@http:Payload User user) returns json|error {
        json response;
        do {
            _ = check dbClient->execute(`
                INSERT INTO Repositories (User,RepoName)
                VALUES (${user.user}, ${user.repo});`);
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
}
