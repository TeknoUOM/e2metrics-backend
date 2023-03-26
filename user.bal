
type Repository record {
    int 'id;
    string 'name;
    string 'full_name;
    string|() 'description?;
};

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
}
