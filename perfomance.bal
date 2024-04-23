import ballerina/io;
import ballerina/regex;
import ballerina/sql;
import ballerina/time;

type Perfomance record {
    string Date;
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

function setRepositoryPerfomance(string ownername, string reponame, string UserId, string accessToken) {

    float IssuesFixingFrequency = 0;
    float BugFixRatio = 0;
    int CommitCount = 0;
    int totalNumberOfLines = 0;
    float MeanLeadFixTime = 0;
    int PullRequestFrequency = 0;
    int WeeklyCommitCount = 0;
    int OpenedIssuesCount = 0;
    int AllIssuesCount = 0;
    float WontFixIssuesRatio = 0;
    int MeanPullRequestResponseTime = 0;
    int PullRequestCount = 0;
    float MeanLeadTimeForPulls = 0;
    float ResponseTimeforIssue = 0;
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

    string dateTime = time:utcToString(time:utcNow());
    string[] dateAndTimeArray = regex:split(dateTime, "T");

    do {

        _ = check dbClient->execute(`
	            INSERT INTO DailyPerfomance (Date,Ownername,Reponame,IssuesFixingFrequency,BugFixRatio,CommitCount,totalNumberOfLines,MeanLeadFixTime,PullRequestFrequency,WeeklyCommitCount,OpenedIssuesCount,AllIssuesCount,WontFixIssuesRatio,MeanPullRequestResponseTime,PullRequestCount,MeanLeadTimeForPulls,ResponseTimeforIssue,UserId)
	            VALUES (${dateAndTimeArray[0]},${ownername},${reponame},${IssuesFixingFrequency},${BugFixRatio},${CommitCount},${totalNumberOfLines},${MeanLeadFixTime},${PullRequestFrequency},${WeeklyCommitCount},${OpenedIssuesCount},${AllIssuesCount},${WontFixIssuesRatio},${MeanPullRequestResponseTime},${PullRequestCount},${MeanLeadTimeForPulls},${ResponseTimeforIssue},${UserId});`);

    } on fail var e {
        io:println(e.toString());
    }

    do {
        AlertLimitsInDB[] data = check getUserAlertLimits(UserId);

        if (WontFixIssuesRatio > data[0].'WontFixIssuesRatio) {
            do {
                _ = check setUserAlerts(UserId, ownername + "/ " + reponame + "/ " + "Won't Fix Issue Ratio exceeded");
            }
        }
        if (WeeklyCommitCount <= data[0].'WeeklyCommitCount) {
            do {
                _ = check setUserAlerts(UserId, ownername + "/ " + reponame + "/ " + "Weekly Commit Count is low");
            }
        }
        if (MeanPullRequestResponseTime >= data[0].'MeanPullRequestResponseTime) {
            do {
                _ = check setUserAlerts(UserId, ownername + "/ " + reponame + "/ " + "Mean Pull Request Response Time is exceeded");
            }
        }
        if (MeanLeadTimeForPulls >= data[0].'MeanLeadTimeForPulls) {
            do {
                _ = check setUserAlerts(UserId, ownername + "/ " + reponame + "/ " + "Mean Lead Time for Pulls exceeded");
            }
        }
        if (ResponseTimeforIssue >= data[0].'ResponseTimeforIssue) {
            do {
                _ = check setUserAlerts(UserId, ownername + "/ " + reponame + "/ " + "Response Time for Issue exceeded");
            }
        }

    } on fail var e {
        io:println(e.toString());
    }

}

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

    do {
        data = check codetabsAPI->get("/v1/loc/?github=" + ownername + "/" + reponame);
        foreach var item in data {
            int linesOfCode = check item.linesOfCode;
            totalNumberOfLines += linesOfCode;
        }
        foreach var item in data {
            languages.push({
                language: check item.language,
                lines: check item.lines
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
        if (totalIssuesCount == 0) {
            IssuesFixingFrequency = 0;
        } else {
            IssuesFixingFrequency = fixedIssuesCount / totalIssuesCount;
        }

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

        if (totalWeightedIssues == 0) {
            BugFixRatio = 0;
        } else {
            BugFixRatio = fixedIssues / totalWeightedIssues;
        }
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
        if (data.length() == 0) {
            meanLeadTime = 0;
        } else {
            meanLeadTime = <float>(fixTime) / data.length();
        }

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

        if (AllIssuesCount == 0) {
            WontFixIssuesRatio = 0;
        } else {
            WontFixIssuesRatio = <float>(WontFixIssuesCount / AllIssuesCount);
        }

        return WontFixIssuesRatio;
    } on fail var e {
        return e;
    }
}

function getMeanPullRequestResponseTime(string ownername, string reponame, string accessToken) returns int|error {

    json[] data;
    int ResponseTime = 0;
    int meanResponseTime;
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
        if (data.length() == 0) {
            meanResponseTime = 0;
        } else {
            meanResponseTime = (ResponseTime / data.length());
        }
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
    if (createdTime.length() == 0) {
        MeanLeadTime = 0;
    } else {
        MeanLeadTime = <float>TotalLeadtime / (createdTime.length());
    }

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

            if (eventData.length() != 0) {
                Event firstEvent = check eventData[0].cloneWithType(Event);
                string created_at = <string>firstEvent?.'created_at;
                time:Utc firstEventTime = check time:utcFromString(created_at);

                Totaltime = +(<float>(firstEventTime[0] - createdAtTime[0]));

            } else {
                responseTime = 0;
            }

        }
        if (data.length() == 0) {
            responseTime = 0;
        } else {
            responseTime = Totaltime / (data.length());
        }
        return responseTime;

    } on fail var e {

        return e;

    }
}

function getMonthlyReport(string userId, string startDate, string endDate) returns Perfomance[]|error {
    Perfomance[] records = [];

    int i = 0;

    sql:ParameterizedQuery query2 = `SELECT * FROM E2Metrices.DailyPerfomance WHERE UserId=${userId} AND Date BETWEEN ${startDate} AND ${endDate}  order by Date`;

    stream<Perfomance, sql:Error?> Result = dbClient->query(query2);

    check from Perfomance performance in Result

        do {
            records[i] = performance;
            i += 1;
        };

    return records;

}
