import ballerina/http;
import ballerina/time;

listener http:Listener httpListener = new(8080);

map<string> headers = {
    "Accept": "application/vnd.github.v3+json",
    "Authorization": "Bearer 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",
    "X-GitHub-Api-Version": "2022-11-28"
};

http:Client github = check new ("https://api.github.com");

service /getWeeklyPullRequestCount on httpListener {
    resource function get getWeeklyPullRequestCount(string ownername, string reponame, string weekstart) returns json|error {
        json[] data = [];
        json returnData;
        
        string since = time:utcToString(time:utcNow());

       

        do {
            data = check github->get("/repos/" + ownername + "/" + reponame + "/pulls?state=all&since=" + since);
            returnData = {
                ownername: ownername,
                reponame: reponame,
                WeeklyPullRequestCount: data.length()
            };
        } on fail var e {
            returnData = {"message": e.toString()};
        }

        return returnData;
    }
}
