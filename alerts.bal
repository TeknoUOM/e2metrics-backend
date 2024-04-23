import ballerina/sql;
import ballerina/time;

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
    do {
        sql:ExecutionResult|sql:Error result = check dbClient->execute(`
	            UPDATE AlertLimits
                SET WontFixIssuesRatio= ${wontFixIssuesRatio},WeeklyCommitCount=${weeklyCommitCount},MeanPullRequestResponseTime=${meanPullRequestResponseTime},MeanLeadTimeForPulls=${meanLeadTimeForPulls},ResponseTimeforIssue=${responseTimeforIssue} WHERE UserID=${userId}`);
        return result;
    } on fail var err {
        return err;
    }

};

public function getUserAlertLimits(string userId) returns AlertLimitsInDB[]|error {
    do {
        stream<AlertLimitsInDB, sql:Error?> resultStream = dbClient->query(`SELECT * FROM AlertLimits WHERE UserID = ${userId}`);
        return from AlertLimitsInDB limits in resultStream
            select limits;
    } on fail error e {
        return e;
    }

};

public function setUserAlerts(string userId, string alert) returns sql:ExecutionResult|error {

    string dateTime = time:utcToString(time:utcNow());
    dateTime = dateTime.substring(0, 19);
    do {
        sql:ExecutionResult|sql:Error result = check dbClient->execute(`
	            INSERT into Alerts (DateTime,Alert,UserID)
                VALUES (${dateTime},${alert},${userId});`);
        return result;
    } on fail var err {
        return err;
    }

};

public function getUserAlerts(string userId) returns AlertsInDB[]|error {
    do {
        stream<AlertsInDB, sql:Error?> resultStream = dbClient->query(`SELECT * FROM Alerts  WHERE UserID = ${userId} AND isShowed=${false} ORDER BY DateTime ASC`);
        return from AlertsInDB limits in resultStream
            select limits;
    } on fail error e {
        return e;
    }

};

public function setUserAlertsIsShowed(string userId) returns sql:ExecutionResult|error {
    do {
        sql:ExecutionResult|sql:Error result = check dbClient->execute(`
	            UPDATE Alerts SET isShowed=${true} WHERE UserID = ${userId};`);
        return result;
    } on fail var err {
        return err;
    }

};
