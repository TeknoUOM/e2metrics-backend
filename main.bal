import ballerina/http;
import ballerina/os;
import ballerina/sql;
import ballerinax/mysql;
import ballerina/io;
import ballerinax/mysql.driver as _;
import ballerina/time;
import ballerina/task;
import ballerina/crypto;

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
    string 'events_url?;
    string 'created_at?;
};

type Pulls record {
    string|() 'created_at?;
};

type Event record {
    string|() 'created_at?;
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

function getCommitCount(string ownername, string reponame, string accessToken) returns int|error {
    json[] data;
    int commitCount;
    map<string> headers = {
        "Accept": "application/vnd.github.v3+json",
        "Authorization": "Bearer " + accessToken,
        "X-GitHub-Api-Version": "2022-11-28"
    };
    do {
        data = check github->get("/repos/" + ownername + "/" + reponame + "/commits", headers);

        commitCount = data.length();

    }

    return commitCount;
};

function getLinesOfCode(string ownername, string reponame, string accessToken) returns json|error {
    json[] data;
    json returnData;
    int totalNumberOfLines = 0;
    json[] languages = [];
    map<string> headers = {
        "Accept": "application/vnd.github.v3+json",
        "Authorization": "Bearer " + accessToken,
        "X-GitHub-Api-Version": "2022-11-28"
    };

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
        return returnData;
    } on fail var e {
        return e;
    }

};

function getIssuesFixingFrequency(string ownername, string reponame, string accessToken) returns float|error {
    json[] data;
    int totalIssuesCount = 0;
    float fixedIssuesCount = 0;
    float IssuesFixingFrequency;
    map<string> headers = {
        "Accept": "application/vnd.github.v3+json",
        "Authorization": "Bearer " + accessToken,
        "X-GitHub-Api-Version": "2022-11-28"
    };

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
        return IssuesFixingFrequency;
    } on fail var e {
        return e;
    }

};

function getBugFixRatio(string ownername, string reponame, string accessToken) returns float|error {
    json[] data;
    int totalWeightedIssues = 0;
    float fixedIssues = 0;
    float BugFixRatio;
    map<string> headers = {
        "Accept": "application/vnd.github.v3+json",
        "Authorization": "Bearer " + accessToken,
        "X-GitHub-Api-Version": "2022-11-28"
    };

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
        return BugFixRatio;
    } on fail var e {
        return e;
    }
};

function getMeanLeadFixTime(string ownername, string reponame, string accessToken) returns float|error {

    json[] data;
    float meanLeadTime;
    int fixTime = 0;
    map<string> headers = {
        "Accept": "application/vnd.github.v3+json",
        "Authorization": "Bearer " + accessToken,
        "X-GitHub-Api-Version": "2022-11-28"
    };

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
                fixTime += (t2[0] - t1[0]);

            } on fail {
                continue;
            }

        }
        meanLeadTime = <float>(fixTime) / data.length();

    }

    return meanLeadTime;
}

function getPullRequestFrequency(string ownername, string reponame, string accessToken) returns int|error {

    json[] data;
    int frequency = 0;
    time:Utc utc = time:utcNow();
    time:Civil civil = time:utcToCivil(utc);
    map<string> headers = {
        "Accept": "application/vnd.github.v3+json",
        "Authorization": "Bearer " + accessToken,
        "X-GitHub-Api-Version": "2022-11-28"
    };

    do {
        data = check github->get("/repos/" + ownername + "/" + reponame + "/pulls", headers);

        foreach json item in data {
            time:Civil openTime;

            do {
                string openedTime = check item.created_at;
                openTime = check time:civilFromString(openedTime);
                if (openTime["month"] == civil["month"]) {
                    frequency = frequency + 1;
                }

            } on fail {
                continue;
            }

        }
        return frequency;
    } on fail var e {
        return e;
    }
}

function getWeeklyCommitCount(string ownername, string reponame, string accessToken) returns int|error {

    map<json> data;
    map<string> headers = {
        "Accept": "application/vnd.github.v3+json",
        "Authorization": "Bearer " + accessToken,
        "X-GitHub-Api-Version": "2022-11-28"
    };
    do {
        data = check github->get("/repos/" + ownername + "/" + reponame + "/stats/participation", headers);
        json[] temp = <json[]>data.get("all");
        int weeklyCommitCount = check temp[temp.length() - 1];
        return weeklyCommitCount;
    } on fail var e {
        return e;
    }
}

function getOpenedIssuesCount(string ownername, string reponame, string accessToken) returns int|error {

    json[] data;
    map<string> headers = {
        "Accept": "application/vnd.github.v3+json",
        "Authorization": "Bearer " + accessToken,
        "X-GitHub-Api-Version": "2022-11-28"
    };
    do {
        data = check github->get("/repos/" + ownername + "/" + reponame + "/issues?state=open", headers);
        int OpenedIssuesCount = data.length();
        return OpenedIssuesCount;
    } on fail var e {
        return e;
    }
}

function getAllIssuesCount(string ownername, string reponame, string accessToken) returns int|error {

    json[] data;
    map<string> headers = {
        "Accept": "application/vnd.github.v3+json",
        "Authorization": "Bearer " + accessToken,
        "X-GitHub-Api-Version": "2022-11-28"
    };
    do {
        data = check github->get("/repos/" + ownername + "/" + reponame + "/issues?state=all", headers);
        int AllIssuesCount = data.length();
        return AllIssuesCount;
    } on fail var e {
        return e;
    }
}

function getWontFixIssuesRatio(string ownername, string reponame, string accessToken) returns float|error {

    json[] data;
    map<string> headers = {
        "Accept": "application/vnd.github.v3+json",
        "Authorization": "Bearer " + accessToken,
        "X-GitHub-Api-Version": "2022-11-28"
    };
    do {
        float WontFixIssuesRatio;
        data = check github->get("/repos/" + ownername + "/" + reponame + "/issues?state=all", headers);
        int AllIssuesCount = data.length();
        data = check github->get("/repos/" + ownername + "/" + reponame + "/issues?state=all&labels=wontfix", headers);
        int WontFixIssuesCount = data.length();
        WontFixIssuesRatio = <float>(WontFixIssuesCount / AllIssuesCount);
        return WontFixIssuesRatio;
    } on fail var e {
        return e;
    }
}

function getMeanPullRequestResponseTime(string ownername, string reponame, string accessToken) returns int|error {

    json[] data;
    int ResponseTime = 0;
    map<string> headers = {
        "Accept": "application/vnd.github.v3+json",
        "Authorization": "Bearer " + accessToken,
        "X-GitHub-Api-Version": "2022-11-28"
    };

    do {
        data = check github->get("/repos/" + ownername + "/" + reponame + "/pulls", headers);

        foreach json item in data {
            time:Utc t1;
            time:Utc t2;
            do {
                string createdTime = check item.created_at;
                t1 = check time:utcFromString(createdTime);
            }

            do {
                string updatedTime = check item.updated_at;
                t2 = check time:utcFromString(updatedTime);
                ResponseTime += (t2[0] - t1[0]);

            } on fail {
                continue;
            }

        }

        int meanResponseTime = (ResponseTime / data.length());

        return meanResponseTime;

    } on fail var e {
        return e;
    }
}

function getPullRequestCount(string ownername, string reponame, string accessToken) returns int|error {

    json[] data;
    map<string> headers = {
        "Accept": "application/vnd.github.v3+json",
        "Authorization": "Bearer " + accessToken,
        "X-GitHub-Api-Version": "2022-11-28"
    };
    do {
        data = check github->get("/repos/" + ownername + "/" + reponame + "/pulls", headers);
        int pullRequestCount = data.length();
        return pullRequestCount;
    } on fail var e {
        return e;
    }
}

function getMeanLeadTimeForPulls(string ownername, string reponame, string accessToken) returns float|error {

    json[] data;
    json[] createdTime = [];
    int TotalLeadtime = 0;
    float MeanLeadTime = 0;
    map<string> headers = {
        "Accept": "application/vnd.github.v3+json",
        "Authorization": "Bearer " + accessToken,
        "X-GitHub-Api-Version": "2022-11-28"
    };

    do {
        data = check github->get("/repos/" + ownername + "/" + reponame + "/pulls", headers);
        foreach var item in data {
            Pulls pullreqs = check item.cloneWithType(Pulls);
            createdTime.push(pullreqs?.created_at);
        }
    } on fail var e {
        return e;
    }

    time:Utc t1;
    time:Utc t2;

    foreach int i in 0 ... (createdTime.length() - 2) {
        do {
            t1 = check time:utcFromString(<string>createdTime[i]);
            t2 = check time:utcFromString(<string>createdTime[i + 1]);
            TotalLeadtime = +(t1[0] - t2[0]);
        }
        on fail var e {
            return e;
        }
    }
    MeanLeadTime = <float>TotalLeadtime / (createdTime.length());
    return MeanLeadTime;
}

function getResponseTimeforIssue(string ownername, string reponame, string accessToken) returns float|error {

    json[] data;
    json[] eventData;
    float Totaltime = 0;
    float responseTime = 0;
    map<string> headers = {
        "Accept": "application/vnd.github.v3+json",
        "Authorization": "Bearer " + accessToken,
        "X-GitHub-Api-Version": "2022-11-28"
    };

    do {

        data = check github->get("/repos/" + ownername + "/" + reponame + "/issues?state=all", headers);

        foreach json jsonIssues in data {
            Issues issue = check jsonIssues.cloneWithType(Issues);
            string createdAt = <string>issue.'created_at;
            time:Utc createdAtTime = check time:utcFromString(createdAt);
            string eventUrl = <string>issue.events_url;
            eventUrl = eventUrl.substring(22);
            eventData = check github->get(eventUrl, headers);

            Event firstEvent = check eventData[0].cloneWithType(Event);
            string created_at = <string>firstEvent?.'created_at;
            time:Utc firstEventTime = check time:utcFromString(created_at);

            Totaltime = +(<float>(firstEventTime[0] - createdAtTime[0]));
        }
        responseTime = Totaltime / (data.length());
        return responseTime;

    } on fail var e {

        return e;

    }
}

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowCredentials: true,
        allowMethods: ["GET", "POST", "OPTIONS", "PUT"]
    }
}
service / on httpListener {
    resource function get metrics/getIssuesFixingFrequency(string ownername, string reponame, string accessToken) returns json|error {
        json returnData;
        float IssuesFixingFrequency;
        do {
            IssuesFixingFrequency = check getIssuesFixingFrequency(ownername, reponame, accessToken);
            returnData = {
                "ownername": ownername,
                "reponame": reponame,
                "IssuesFixingFrequency": IssuesFixingFrequency
            };

        } on fail var e {
            return e;
        }
        return returnData;
    }

    resource function get metrics/getBugFixRatio(string ownername, string reponame, string accessToken) returns json|error {
        json returnData;
        do {
            float BugFixRatio = check getBugFixRatio(ownername, reponame, accessToken);
            returnData = {
                "ownername": ownername,
                "reponame": reponame,
                "BugFixRatio": BugFixRatio
            };
            return returnData;
        } on fail var e {
            return e;
        }

    }

    resource function get metrics/getMeanLeadFixTime(string ownername, string reponame, string accessToken) returns json|error {

        json returnData;

        do {

            float meanLeadTime = check getMeanLeadFixTime(ownername, reponame, accessToken);
            returnData = {
                ownername: ownername,
                reponame: reponame,
                meanLeadTime: meanLeadTime
            };
            return returnData;

        } on fail var e {
            return e;
        }
    }

    resource function get metrics/getPullRequestFrequency(string ownername, string reponame, string accessToken) returns json|error {

        json returnData;

        do {

            int frequency = check getPullRequestFrequency(ownername, reponame, accessToken);

            returnData = {
                ownername: ownername,
                reponame: reponame,
                pullRequestfrequency: frequency

            };
            return returnData;
        } on fail var e {
            return e;
        }

    }
    resource function get metrics/getLinesOfCode(string ownername, string reponame, string accessToken) returns json|error {

        do {
            json returnData = check getLinesOfCode(ownername, reponame, accessToken);
            returnData = {
                "ownername": ownername,
                "reponame": reponame,
                "totalNumberOfLines": check returnData.totalNumberOfLines,
                "languages": check returnData.languages
            };
            return returnData;
        } on fail var e {
            return e;
        }

    }
    resource function get metrics/getWeeklyCommitCount(string ownername, string reponame, string accessToken) returns json|error {

        json returnData;
        do {
            json LastWeekCommitCount = check getWeeklyCommitCount(ownername, reponame, accessToken);
            returnData = {
                ownername: ownername,
                reponame: reponame,
                LastWeekCommitCount: LastWeekCommitCount
            };
            return returnData;
        } on fail var e {
            return e;
        }

    }

    resource function get metrics/getOpenedIssuesCount(string ownername, string reponame, string accessToken) returns json|error {

        json returnData;
        do {
            int OpenedIssuesCount = check getOpenedIssuesCount(ownername, reponame, accessToken);
            returnData = {
                ownername: ownername,
                reponame: reponame,
                OpenedIssuesCount: OpenedIssuesCount

            };
            return returnData;
        } on fail var e {
            return e;
        }

    }
    resource function get metrics/getAllIssuesCount(string ownername, string reponame, string accessToken) returns json|error {

        json returnData;
        do {
            int AllIssuesCount = check getAllIssuesCount(ownername, reponame, accessToken);
            returnData = {
                ownername: ownername,
                reponame: reponame,
                AllIssuesCount: AllIssuesCount

            };
            return returnData;
        } on fail var e {
            return e;
        }

    }
    resource function get metrics/getWontFixIssuesRatio(string ownername, string reponame, string accessToken) returns json|error {

        json returnData;
        do {
            float WontFixIssuesRatio = check getWontFixIssuesRatio(ownername, reponame, accessToken);
            returnData = {
                ownername: ownername,
                reponame: reponame,
                WontFixIssuesRatio: WontFixIssuesRatio

            };
            return returnData;
        } on fail var e {
            return e;
        }

    }
    resource function get metrics/getMeanPullRequestResponseTime(string ownername, string reponame, string accessToken) returns json|error {

        json returnData;
        do {
            int meanResponseTime = check getMeanPullRequestResponseTime(ownername, reponame, accessToken);

            returnData = {
                meanResponseTime: meanResponseTime,
                ownername: ownername,
                reponame: reponame
            };
            return returnData;

        } on fail var e {
            return e;
        }
    }
    resource function get metrics/getPullRequestCount(string ownername, string reponame, string accessToken) returns json|error {

        json returnData;
        do {
            int pullRequestCount = check getPullRequestCount(ownername, reponame, accessToken);
            returnData = {
                ownername: ownername,
                reponame: reponame,
                PullRequestCount: pullRequestCount

            };
            return returnData;
        } on fail var e {
            return e;
        }
    }
    resource function get metrics/getMeanLeadTimeForPulls(string ownername, string reponame, string accessToken) returns json|error {

        json returnData;

        do {
            float MeanLeadTime = check getMeanLeadTimeForPulls(ownername, reponame, accessToken);
            returnData = {
                ownername: ownername,
                reponame: reponame,
                MeanLeadTime: MeanLeadTime
            };
            return returnData;
        } on fail var e {
            return e;
        }
    }

    resource function get metrics/getResponseTimeforIssue(string ownername, string reponame, string accessToken) returns json|error {

        json returnData;

        do {
            float responseTimeforIssue = check getResponseTimeforIssue(ownername, reponame, accessToken);
            returnData = {
                ownername: ownername,
                reponame: reponame,
                responseTimeforIssue: responseTimeforIssue
            };
            return returnData;
        } on fail var e {
            return e;
        }

    }

    resource function get metrics/getPerfomances(string userId) returns Perfomance[]|error {

        stream<Perfomance, sql:Error?> Stream = dbClient->query(`SELECT * FROM Perfomance ORDER BY date DESC LIMIT 1`);

        return from Perfomance perfomance in Stream
            select perfomance;
    }

}

type Perfomance record {
    string DateTime;
    string Ownername;
    string Reponame;
    string UserId;
    float IssuesFixingFrequency;
    float BugFixRatio;
    int CommitCount;
    int totalNumberOfLines;
    float MeanLeadFixTime;
    int PullRequestFrequency;
    int WeeklyCommitCount;
    int OpenedIssuesCount;
    int AllIssuesCount;
    float WontFixIssuesRatio;
    int MeanPullRequestResponseTime;
    int PullRequestCount;
    float MeanLeadTimeForPulls;
    float ResponseTimeforIssue;
};

function setRepositoryPerfomance(string ownername, string reponame, string UserId, string accessToken) {

    float IssuesFixingFrequency;
    float BugFixRatio;
    int CommitCount;
    int totalNumberOfLines;
    float MeanLeadFixTime;
    int PullRequestFrequency;
    int WeeklyCommitCount;
    int OpenedIssuesCount;
    int AllIssuesCount;
    float WontFixIssuesRatio;
    int MeanPullRequestResponseTime;
    int PullRequestCount;
    float MeanLeadTimeForPulls;
    float ResponseTimeforIssue;
    do {
        json linesOfCode = check getLinesOfCode(ownername, reponame, accessToken);
        totalNumberOfLines = check linesOfCode.totalNumberOfLines;
        IssuesFixingFrequency = check getIssuesFixingFrequency(ownername, reponame, accessToken);
        BugFixRatio = check getBugFixRatio(ownername, reponame, accessToken);
        CommitCount = check getCommitCount(ownername, reponame, accessToken);
        MeanLeadFixTime = check getMeanLeadFixTime(ownername, reponame, accessToken);
        PullRequestFrequency = check getPullRequestFrequency(ownername, reponame, accessToken);
        WeeklyCommitCount = check getWeeklyCommitCount(ownername, reponame, accessToken);
        OpenedIssuesCount = check getOpenedIssuesCount(ownername, reponame, accessToken);
        AllIssuesCount = check getAllIssuesCount(ownername, reponame, accessToken);
        WontFixIssuesRatio = check getWontFixIssuesRatio(ownername, reponame, accessToken);
        MeanPullRequestResponseTime = check getMeanPullRequestResponseTime(ownername, reponame, accessToken);
        PullRequestCount = check getPullRequestCount(ownername, reponame, accessToken);
        MeanLeadTimeForPulls = check getMeanLeadTimeForPulls(ownername, reponame, accessToken);
        ResponseTimeforIssue = check getResponseTimeforIssue(ownername, reponame, accessToken);

    } on fail var e {
        io:println(e.message());
    }

    time:Utc DateTime = time:utcNow();

    do {
        _ = check dbClient->execute(`
	            INSERT INTO Perfomance (DateTime,Ownername,Reponame,IssuesFixingFrequency,BugFixRatio,CommitCount,totalNumberOfLines,MeanLeadFixTime,PullRequestFrequency,WeeklyCommitCount,OpenedIssuesCount,AllIssuesCount,WontFixIssuesRatio,MeanPullRequestResponseTime,PullRequestCount,MeanLeadTimeForPulls,ResponseTimeforIssue,UserId)
	            VALUES (${DateTime},${ownername},${reponame},${IssuesFixingFrequency},${BugFixRatio},${CommitCount},${totalNumberOfLines},${MeanLeadFixTime},${PullRequestFrequency},${WeeklyCommitCount},${OpenedIssuesCount},${AllIssuesCount},${WontFixIssuesRatio},${MeanPullRequestResponseTime},${PullRequestCount},${MeanLeadTimeForPulls},${ResponseTimeforIssue},${UserId});`);
    } on fail var e {
        io:println(e.toString());
    }
}

type RepositoriesJOINUser record {
    string 'Ownername;
    string 'Reponame;
    string 'UserID;
    byte[] 'GH_AccessToken;
};

class CalculateMetricsPeriodically {

    *task:Job;

    public function execute() {
        do {

            stream<RepositoriesJOINUser, sql:Error?> resultStream = dbClient->query(`SELECT Repositories.Reponame, Repositories.Ownername, Users.GH_AccessToken, Users.UserID FROM Users INNER JOIN Repositories ON Users.UserID=Repositories.UserId;`);
            check from RepositoriesJOINUser row in resultStream
                do {
                    byte[] plainText = check crypto:decryptAesCbc(row.GH_AccessToken, encryptkey, initialVector);
                    string accessToken = check string:fromBytes(plainText);
                    setRepositoryPerfomance(row.'Ownername, row.'Reponame, row.'UserID, accessToken);
                };
        } on fail error e {
            io:println(e.message());
        }

    }
}

time:Utc currentUtc = time:utcNow();
time:Utc newTime = time:utcAddSeconds(currentUtc, 10);
time:Civil time = time:utcToCivil(newTime);

task:JobId result = check task:scheduleJobRecurByFrequency(new CalculateMetricsPeriodically(), 86400, 10, time);
