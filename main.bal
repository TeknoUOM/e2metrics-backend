import ballerina/http;
import ballerina/os;

listener http:Listener httpListener =new (8080);
string API_KEY = os:getEnv("API_KEY");

http:Client github = check new ("https://api.github.com");

map<string> headers = {
    "Accept": "application/vnd.github.v3+json",
    "Authorization": "Bearer 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",
    "X-GitHub-Api-Version":"2022-11-28"
};

service / on httpListener {
    resource function get greeting() returns string {
        return "Hello,World";
    }

}


service /getLinesOfCode on httpListener {

    resource function get .(string github) returns json|error {

        json data;
        http:Client codetabs = check new ("https://api.codetabs.com");
        do {
            data = check codetabs->get("/v1/loc?github=" + github);
        } on fail var e {
            data = {"message": e.toString()};
        }

        return data;
    }

    
}




service /getCommitCount on httpListener {

    resource function get .(string ownername, string reponame) returns json|error {

        json data;

        do {
            data = check github->get("/repos/" + ownername + "/" + reponame + "/commits", headers);
        } on fail var e {
            data = {"message": e.toString()};
        }

        return data;
    }

    

    

    
}
service /getPullsCount on httpListener {

    resource function get .(string ownername, string reponame) returns json|error {
        json data;

        do {
            data = check github->get("/repos/" + ownername + "/" + reponame + "/pulls", headers);
        } on fail var e {
            data = {"message": e.toString()};
        }

        return data;
    }

    
}

service /getOpenedIssuesCount on httpListener {

    resource function get .(string ownername, string reponame) returns json|error {

        json data;
        do {
            data = check github->get("/repos/" + ownername + "/" + reponame + "/issues?state=open", headers);
        } on fail var e {
            data = {"message": e.toString()};
        }

        return data;
    }

}

service /getTotalIssueCount on httpListener {
    resource function get .(string ownername, string reponame) returns json|error {

        json data;

        do {
            data = check github->get("/repos/" + ownername + "/" + reponame + "issues?state=all", headers);
        } on fail var e {
            data = {"message": e.toString()};
        }

        return data;
    }
}
