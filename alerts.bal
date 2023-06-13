import ballerina/sql;
import ballerina/time;
import ballerinax/mysql;

type AlertLimitsInDB record {
    string 'UserID;
    float 'WontFixIssuesRatio;
    int 'WeeklyCommitCount;
    int 'MeanPullRequestResponseTime;
    float 'MeanLeadTimeForPulls;
    float 'ResponseTimeforIssue;
};

type AlertsInDB record {
    string 'UserID;
    string 'DateTime;
    string 'Alert;
};

public function setUserAlertLimits(string userId, float wontFixIssuesRatio, int weeklyCommitCount, int meanPullRequestResponseTime, float meanLeadTimeForPulls, float responseTimeforIssue) returns sql:ExecutionResult|error {
    mysql:Client dbClient = check new (hostname, username, password, "E2Metrices", port);
    do {
        sql:ExecutionResult|sql:Error result = check dbClient->execute(`
	            UPDATE AlertLimits
                SET WontFixIssuesRatio= ${wontFixIssuesRatio},WeeklyCommitCount=${weeklyCommitCount},MeanPullRequestResponseTime=${meanPullRequestResponseTime},MeanLeadTimeForPulls=${meanLeadTimeForPulls},ResponseTimeforIssue=${responseTimeforIssue} WHERE UserID=${userId}`);
        sql:Error? close = dbClient.close();
        return result;
    } on fail var err {
        sql:Error? close = dbClient.close();
        return err;
    }

};

public function getUserAlertLimits(string userId) returns AlertLimitsInDB[]|error {
    mysql:Client dbClient = check new (hostname, username, password, "E2Metrices", port);
    do {
        stream<AlertLimitsInDB, sql:Error?> resultStream = dbClient->query(`SELECT * FROM AlertLimits WHERE UserID = ${userId}`);
        sql:Error? close = dbClient.close();
        return from AlertLimitsInDB limits in resultStream
            select limits;
    } on fail error e {
        sql:Error? close = dbClient.close();
        return e;
    }

};

public function setUserAlerts(string userId, string alert) returns sql:ExecutionResult|error {

    string dateTime = time:utcToString(time:utcNow());
    dateTime = dateTime.substring(0, 19);
    mysql:Client dbClient = check new (hostname, username, password, "E2Metrices", port);
    do {
        sql:ExecutionResult|sql:Error result = check dbClient->execute(`
	            INSERT into Alerts (DateTime,Alert,UserID)
                VALUES (${dateTime},${alert},${userId});`);
        sql:Error? close = dbClient.close();
        return result;
    } on fail var err {
        sql:Error? close = dbClient.close();
        return err;
    }

};

public function getUserAlerts(string userId) returns AlertsInDB[]|error {
    mysql:Client dbClient = check new (hostname, username, password, "E2Metrices", port);
    do {
        stream<AlertsInDB, sql:Error?> resultStream = dbClient->query(`SELECT * FROM Alerts  WHERE UserID = ${userId} ORDER BY DateTime DESC LIMIT 20`);
        sql:Error? close = dbClient.close();
        return from AlertsInDB limits in resultStream
            select limits;
    } on fail error e {
        sql:Error? close = dbClient.close();
        return e;
    }

};
