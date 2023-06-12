import ballerina/http;
import ballerina/os;
import ballerina/sql;
import ballerinax/mysql;
import ballerina/io;
import ballerinax/mysql.driver as _;
import ballerina/time;
import ballerina/task;

mysql:Options mysqlOptions = {
    ssl: {
        mode: mysql:SSL_PREFERRED
    },
    connectTimeout: 10
};
mysql:Client dbClient = check new (hostname, username, password, "E2Metrices", port);

listener http:Listener httpListener = new (8080);
string API_KEY = os:getEnv("API_KEY");

http:Client github = check new ("https://api.github.com");
http:Client codetabsAPI = check new ("https://api.codetabs.com");

map<string> headers = {
    "Accept": "application/vnd.github.v3+json",
    "Authorization": "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",
    "X-GitHub-Api-Version": "2022-11-28"
};

service /primitive2 on httpListener {

    resource function get userDetails() returns json|error {

        json returnData = {};
        string accessToken = check getAuthToken("internal_user_mgt_list");
        io:println(accessToken);

        map<string> asgardeoClientHeaders = {
            "Authorization": "Bearer " + accessToken
        };

        do {
            json data = check asgardeoClient->get("/t/tekno/scim2/Me", asgardeoClientHeaders);
            returnData = {
                name: data
            };
        } on fail var e {
            returnData = {"message": e.toString()};
        }
        return returnData;
    }
}

service / on httpListener {
    resource function get greeting() returns string {
        return "Hello,World";
    }

}

type Label record {
    string 'name?;
};

type pull_request record {
    string|() 'merged_at?;
};

type Issues record {
    string 'url;
    Label[] 'labels;
    pull_request 'pull_request?;
    string created_at;
    string|() closed_at;
};

const map<int> weights = {
    "bug": 10,
    "documentation": 2,
    "duplicate": 0,
    "enhancement": 8,
    "good first issue": 6,
    "help wanted": 5,
    "invalid": 4,
    "question": 7,
    "wontfix": 0
};
const string ownername = "MasterD98";
const string reponame = "tic-tac-toe";

function getLinesOfCode(string ownername, string reponame) returns json {
    json[] data;
    json returnData;
    int totalNumberOfLines = 0;
    json[] languages = [];

    do {
        data = check codetabsAPI->get("/v1/loc/?github=" + ownername + "/" + reponame);
        foreach var item in data {
            int linesOfCode = check item.linesOfCode;
            totalNumberOfLines += linesOfCode;
        }
        foreach var item in data {
            float lines = check item.lines;
            float ratio = (lines / totalNumberOfLines) * 100;
            languages.push({
                language: check item.language,
                lines: check item.lines,
                ratio: ratio
            });
        }
        returnData = {
            "totalNumberOfLines": totalNumberOfLines,
            "languages": languages
        };
    } on fail var e {
        returnData = {"message": e.toString()};
    }
    return returnData;
};

function getCommitCount(string ownername, string reponame) returns int|error {

    json[] data;
    int commitCount;
    do {
        data = check github->get("/repos/" + ownername + "/" + reponame + "/commits", headers);

        commitCount = data.length();

    }

    return commitCount;
};

function getIssuesFixingFrequency(string ownername, string reponame) returns float|error {
    json[] data;
    int totalIssuesCount = 0;
    float fixedIssuesCount = 0;
    float IssuesFixingFrequency;

    do {
        data = check github->get("/repos/" + ownername + "/" + reponame + "/issues?state=all", headers);
        totalIssuesCount = data.length();

        data = check github->get("/repos/" + ownername + "/" + reponame + "/issues?state=closed", headers);

        foreach json issueJson in data {
            Issues issue = check issueJson.cloneWithType(Issues);
            if (issue.pull_request?.'merged_at != "null") {
                fixedIssuesCount = fixedIssuesCount + 1;
            }
        }

        IssuesFixingFrequency = fixedIssuesCount / totalIssuesCount;
    }
    return IssuesFixingFrequency;
};

function getBugFixRatio(string ownername, string reponame) returns float {
    json[] data;
    int totalWeightedIssues = 0;
    float fixedIssues = 0;
    float BugFixRatio;

    do {
        data = check github->get("/repos/" + ownername + "/" + reponame + "/issues?state=all", headers);

        foreach json issue in data {
            Issues issues = check issue.cloneWithType(Issues);
            foreach Label label in issues.labels {
                string[] weightsKeys = weights.keys();

                foreach string weight in weightsKeys {
                    if (label.name == weight) {
                        totalWeightedIssues += weights.get(weight);
                    }
                }
            }
        }

        data = check github->get("/repos/" + ownername + "/" + reponame + "/issues?state=closed", headers);

        foreach json closedJsonIssue in data {
            Issues closedIssue = check closedJsonIssue.cloneWithType(Issues);
            if (closedIssue.pull_request?.merged_at != "null" && closedIssue.labels.length() > 0) {
                foreach Label label in closedIssue.labels {
                    string[] weightsKeys = weights.keys();

                    foreach string weight in weightsKeys {
                        if (label.name == weight) {
                            fixedIssues += <float>weights.get(weight);
                        }
                    }
                }
            }
        }
        BugFixRatio = fixedIssues / totalWeightedIssues;
    } on fail {
        return -1;
    }
    return BugFixRatio;
};

function getMeanLeadFixTime(string ownername, string reponame) returns int|error {

    json[] data;
    int meanLeadTime;
    int fixTime = 0;

    do {
        data = check github->get("/repos/" + ownername + "/" + reponame + "/issues?state=closed", headers);

        foreach json item in data {
            time:Utc t1;
            time:Utc t2;
            do {
                string openedTime = check item.created_at;
                t1 = check time:utcFromString(openedTime);

                string closedTime = check item.closed_at;
                t2 = check time:utcFromString(closedTime);
                io:println(t2[0] - t1[0]);
                fixTime += (t2[0] - t1[0]);

            } on fail {
                continue;
            }

        }
        meanLeadTime = fixTime / data.length();

    }

    return meanLeadTime;
}

function getPullRequestFrequency(string ownername, string reponame) returns int|error {

    json[] data;
    int frequency = 0;
    time:Utc utc = time:utcNow();
    time:Civil civil = time:utcToCivil(utc);

    do {
        data = check github->get("/repos/" + ownername + "/" + reponame + "/pulls", headers);

        foreach json item in data {
            time:Civil openTime;

            do {
                string openedTime = check item.created_at;
                openTime = check time:civilFromString(openedTime);
                io:println("Converted civil value: " + openTime.toString());
                if (openTime["month"] == civil["month"]) {
                    frequency = frequency + 1;
                }

            } on fail {
                continue;
            }

        }
        io:println("pullRequestfrequency = ", frequency);
    }

    return frequency;
}

service /complex on httpListener {
    resource function get getIssuesFixingFrequency(string ownername, string reponame) returns json|error {
        json returnData;
        float IssuesFixingFrequency;
        do {
            IssuesFixingFrequency = check getIssuesFixingFrequency(ownername, reponame);
            returnData = {
                "ownername": ownername,
                "reponame": reponame,
                "IssuesFixingFrequency": IssuesFixingFrequency
            };

        } on fail var e {
            returnData = {
                "message": e.toString()
            };
        }
        return returnData;
    }

    resource function get getBugFixRatio(string ownername, string reponame) returns json|error {
        json returnData;
        returnData = {
            "ownername": ownername,
            "reponame": reponame,
            "BugFixRatio": getBugFixRatio(ownername, reponame)
        };
        return returnData;
    }

    resource function get getMeanLeadFixTime(string ownername, string reponame) returns json|error {

        json returnData;
        int meanLeadTime = 0;

        do {
            meanLeadTime = check getMeanLeadFixTime(ownername, reponame);

            returnData = {
                ownername: ownername,
                reponame: reponame,
                meanLeadTime: meanLeadTime
            };

        } on fail var e {
            returnData = {"message": e.toString()};
        }

        return returnData;
    }

    resource function get getPullRequestFrequency(string ownername, string reponame) returns json|error {

        json returnData;
        int frequency = 0;

        do {
            frequency = check getPullRequestFrequency(ownername, reponame);

            returnData = {
                ownername: ownername,
                reponame: reponame,
                pullRequestfrequency: frequency

            };
        } on fail var e {
            returnData = {"message": e.toString()};
        }

        return returnData;
    }

}

type Perfomance record {
    string date;
    string IssuesFixingFrequency;
    string BugFixRatio;
    int totalNumberOfLines;
};

service /primitive on httpListener {
    resource function get getLinesOfCode(string ownername, string reponame) returns json|error {
        json returendData = getLinesOfCode(ownername, reponame);
        json returnData;
        do {
            returnData = {
                "ownername": ownername,
                "reponame": reponame,
                "totalNumberOfLines": check returendData.totalNumberOfLines,
                "languages": check returendData.languages
            };
        } on fail {
            returnData = {
                "ownername": ownername,
                "reponame": reponame,
                "message": check returendData.message
            };
        }
        return returnData;
    }

    resource function get getCommitCount(string ownername, string reponame) returns json|error {

        json returnData;
        do {
            int commitCount = check getCommitCount(ownername, reponame);
            returnData = {
                ownername: ownername,
                reponame: reponame,
                commitCount: commitCount
            };
        } on fail var e {
            returnData = {"message": e.toString()};
        }

        return returnData;
    }

    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000"]
        }
    }

    resource function get getPerfomances() returns Perfomance[]|error {

        stream<Perfomance, sql:Error?> Stream = dbClient->query(`SELECT * FROM Perfomance`);

        return from Perfomance perfomance in Stream
            select perfomance;
    }

}

class CalculateMetricsPeriodically {

    *task:Job;

    public function execute() {
        json linesOfCode = getLinesOfCode(ownername, reponame);
        int totalNumberOfLines;
        float issuesFixingFrequency;
        int meanLeadFixTime;
        int pullRequestFrequency;
        int commitCount;
        do {
            totalNumberOfLines = check linesOfCode.totalNumberOfLines;
            issuesFixingFrequency = check getIssuesFixingFrequency(ownername, reponame);
            meanLeadFixTime = check getMeanLeadFixTime(ownername, reponame);
            pullRequestFrequency = check getPullRequestFrequency(ownername, reponame);
            commitCount = check getCommitCount(ownername, reponame);
        } on fail var e {
            io:println(e.message());
        }
        float bugFixRatio = getBugFixRatio(ownername, reponame);
        time:Utc currentUtc = time:utcNow();

        do {
            _ = check dbClient->execute(`
	            INSERT INTO Perfomance (date,IssuesFixingFrequency,BugFixRatio,totalNumberOfLines,CommitCount,MeanLeadFixTime,PullRequestFrequency)
	            VALUES (${currentUtc}, ${issuesFixingFrequency}, ${bugFixRatio}, ${totalNumberOfLines},${commitCount},${meanLeadFixTime},${pullRequestFrequency});`);
        } on fail var e {
            io:println(e.toString());
        }
    }
}

time:ZoneOffset zoneOffset = {
    hours: 5,
    minutes: 30
};

time:Utc currentUtc = time:utcNow();
time:Utc newTime = time:utcAddSeconds(currentUtc, 10);
time:Civil time = time:utcToCivil(newTime);

task:JobId result = check task:scheduleJobRecurByFrequency(new CalculateMetricsPeriodically(), 86400, 10, time);
