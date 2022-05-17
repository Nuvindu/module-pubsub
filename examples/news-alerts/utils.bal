import ballerina/io;
public function getNews() returns string[]|error {
    json inputs = check io:fileReadJson("modules/resources/data_source.json");
    string[] news = [];
    foreach json data in <json[]>inputs {
        news.push(<string> check data.news);
    }
    return news;
}
