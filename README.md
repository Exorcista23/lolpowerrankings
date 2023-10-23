# lolpowerrankings
League of Legends Global Power Rankings Repository

# Description -

In this project, I aimed to create a LoL Global Power Rankings for teams based on their match history according to an elo-based algorithm, taking into account strength of competition and recent performance.

# Game Data -

The data used in this project was sourced from the Amazon X Riot Games Global Power Rankings Dataset hosted on Devpost. Data was pulled from AWS S3 Buckets found at

[https://power-rankings-dataset-gprhack.s3.us-west-2.amazonaws.com/](https://power-rankings-dataset-gprhack.s3.us-west-2.amazonaws.com/)

To start, data tables were created in Amazon Glue to be used in Amazon Athena queries. The scripts for creating the initial tables can be found at s3://power-rankings-dataset-gprhack/athena-ready/ddl/

Initial Exploration of the available dataset revealed a large dataset that included more features than was ultimately deemed necessary for my scope. While a large number of factors can play into a team's strength, I believe that a team's match history of wins and losses tells the best tale with regards to overall team strength as things like laning strength or teamfight cohesion are more nebulous and cannot be easily translated into team performance, at least not at my current level. I would love to get more into this given more time, as I believe one powerful measure of team macro strength is their baron stats: how well they secure the baron take, how well they utilize the buff to gain gold leads or close out the game, how well they take a baron fight from behind. These are all topics that I believe play into a team's macro and cohesive ability, but I did not have time for them in this project.

My first steps in this project was to create a viable match history using the data available. This was rather difficult at first, as I was learning how to utilize AWS for the first time, as well as being unsure on where to begin my match history construction. After much struggling with the games data table, I ultimately decided that parsing the tournaments table for games played would yield the best results for an accurate match history. From the tournaments table, I parsed the table to construct a match history containing gameids, tournament information, as well as the obvious participating team information. This match history is the foundation of my project as I will be constructing an elo based algorithm focused on match history.

# Data Cleaning and Preparation -

To manipulate the dataset, I downloaded the tournaments, teams, and leagues data from Amazon Athena. I also downloaded the tournaments.jsonl file from AWS during my exploration, and this would later come in handy when attempting to parse tournament information in my project.

I found that the game\_time column within the games table to need manipulation to return to a human readable format. More specifically, it first needed to be divided by 60, at which point dropping the last 3 digits would leave the game timer in minutes, while the last 3 digits would need to be divided by 100/60 in order to return to seconds.

Furthermore, I found that certain tournaments had stages that were oddly named, such as regional\_qualifiers for LCK 2022 Summer. This should have been named Regional Qualifiers. To rectify this, I had to apply a standardization to all stage names. I also would standardize tournament names as some would include the region and year, while others would not.

The most difficult to resolve issue was reconstructing a match history from the tournaments table. Initially, I had begun by unnesting the tournaments table in Amazon Athena. This had proven more difficult for me to understand, so I looked to other alternatives to manipulate the data via Python. Initially, the tournaments.csv file would prove useful. However, parsing the game data from the nested tournament stages field would prove difficult. I would then parse the data from the tournaments.jsonl file, which would allow for easy parsing of the stages field. However, for some unknown reason this import would always import the wrong tournament and leagueids, they would be very slightly off(± 10) no matter if the data was read as a string or int. To rectify this, I ultimately decided to merge the tournaments.csv and tournaments.jsonl dataframe imports together to get the best of both worlds, the easy parsing from tournaments.jsonl and the correct ids from tournaments.csv.

# Elo Algorithm -

Elo is a chess based matchmaking rating that is widely used around the world. I adopted an algorithm based on the in order to provide a team ranking.

To begin, I seeded each team based on their home region and tier. While traditionally LoL esports lists teams in 2 tiers(Major and Minor Regions), I decided that it would be best to seed teams in 3 tiers given recent Worlds performances. This is to reflect the strength of competition within each region, as LPL and LCK teams tend to outperform LEC and LCS despite both pairings nominally being Major Regions.

| | Tier 1 | Tier 2 | Tier 3 |
| --- | --- | --- | --- |
| Regions | LPL, LCK | LEC, LCS | Rest |
| Seed Elo | 1500 | 1250 | 1000 |

The Elo Algorithm used in this project is as follows:

- EAfter = Ebefore + I \* (W - Wexpected) \* R


EAfter = Elo points after match

EBefore = Elo points before match

I = Match Importance

- (15-65 from Regular Season/Promotion Series to Worlds Knockouts)

W = Match Result(0 - Loss, 1 - Win)

WExpected = Expected Match Result

- WExpected = 1/(1 + 10^(-(EBefore_TeamA - EBefore_TeamB)/600))

R = Match Recency

- R = (1/2) ^ 2023 - year

# Considerations -

A few conditions were included in this algorithm to address issues with regards to international and playoff play. Losses were additionally weighted according to the following table to prevent excessive elo losses from extra games played at a higher level of competition.


| | Groups/Round Robin | Knockouts |
| --- | --- | --- |
| Regular Season | 1 | 0.5 |
| MSI | 0.5 | 0.25 |
| Worlds | 0.25 | 0 |

The results after applying the elo algorithm for user specified tournaments(or all if none are specified) are then saved to a CSV file.
