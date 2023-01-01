import ballerina/http;
import ballerina/os;

listener http:Listener httpListener =new (8080);
string API_KEY = os:getEnv("API_KEY");

http:Client github = check new ("https://api.github.com");

map<string> headers = {
    "Accept": "application/vnd.github.v3+json",
    "Authorization": "token " + API_KEY
};

service / on httpListener {
    resource function get greeting() returns string {
        return "Hello,World";
    }

}


service /getLinesOfCode on httpListener {

    resource function get getLinesOfCode(string ownername, string reponame) returns json|error {

        json data;

        do {
            data = check github->get("https: //api.codetabs.com/v1/loc?github=" + ownername + "/" + reponame, headers);
        } on fail var e {
            data = {"message": e.toString()};
        }

        return data;
    }

    
}




service /getCommitCount on httpListener {

    resource function get getCommitCount(string ownername, string reponame) returns json|error {

        json data;

        do {
            data = check github->get("https://api.github.com/repos/"+ownername+ "/"+reponame + "/commits", headers);
        } on fail var e {
            data = {"message": e.toString()};
        }

        return data;
    }

    

    

    
}
service /getPullsCount on httpListener {

    resource function get getPullsCount(string ownername, string reponame) returns json|error {
        json data;

        do {
            data = check github->get("https://api.github.com/repos/" + ownername + "/" + reponame + "/pulls", headers);
        } on fail var e {
            data = {"message": e.toString()};
        }

        return data;
    }

    
}

service /getOpenedIssuesCount on httpListener {

    resource function get getOpenedIssuesCount(string ownername, string reponame) returns json|error {

        json data;
        do {
            data = check github->get("https://api.github.com/repos/" + ownername + "/" + reponame + "/issues?state=open", headers);
        } on fail var e {
            data = {"message": e.toString()};
        }

        return data;
    }

}

service /getTotalIssueCount on httpListener {
    resource function get getTotalIssueCount(string ownername, string reponame) returns json|error {

        json data;

        do {
            data = check github->get("https://api.github.com/repos/" + ownername + "/" + reponame + "issues?state=all", headers);
        } on fail var e {
            data = {"message": e.toString()};
        }

        return data;
    }
}
