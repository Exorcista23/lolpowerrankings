-- For use in Amazon Athena
CREATE OR REPLACE VIEW "match_history" AS 
(
   SELECT
     win.platformgameid gameid
   , blueside.esportsgameid egameid
   , win.eventtime event_time
   , win.gametime game_time
   , blueside.team_id blue_team_id
   , redside.team_id red_team_id
   , win.winningteam winning_side
   , (CASE win.winningteam WHEN 100 THEN blueside.team_id WHEN 200 THEN redside.team_id ELSE 'unknown' END) winning_team
   FROM
     ((lol.game_win win
   INNER JOIN (
      SELECT *
      FROM
        (team_games tgames
      INNER JOIN teams tdata ON (tgames.teamid = tdata.team_id))
      WHERE (side = 100)
   )  blueside ON (blueside.platformgameid = win.platformgameid))
   INNER JOIN (
      SELECT *
      FROM
        (team_games tgames
      INNER JOIN teams tdata ON (tgames.teamid = tdata.team_id))
      WHERE (side = 200)
   )  redside ON (redside.platformgameid = win.platformgameid))
   WHERE (eventtype = 'game_end')
) 