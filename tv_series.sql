#Group 14

# Task 2

# Solution 1

CREATE OR REPLACE VIEW top_series_cast AS
SELECT s.series_id, s.series_title, 
GROUP_CONCAT(DISTINCT a.actor_name ORDER BY a.actor_name SEPARATOR ', ') AS cast
FROM series AS s
RIGHT JOIN episodes AS e
ON s.series_id = e.series_id
RIGHT JOIN actor_episode AS ae
ON e.episode_id = ae.episode_id
LEFT JOIN actors AS a
ON ae.actor_id = a.actor_id
WHERE s.rating >= 4.00
GROUP BY s.series_id;

# Solution 2

CREATE OR REPLACE VIEW actor_minutes AS
SELECT 
    a.actor_id,
    a.actor_name,
    COALESCE(SUM(uh.minutes_played), 0) AS total_minutes_played
FROM actors a
JOIN actor_episode ae 
    ON a.actor_id = ae.actor_id
LEFT JOIN user_history uh 
    ON ae.episode_id = uh.episode_id
GROUP BY a.actor_id, a.actor_name
ORDER BY total_minutes_played DESC;

# Solution 3

DELIMITER //
CREATE TRIGGER AdjustRating
BEFORE INSERT ON user_history
FOR EACH ROW BEGIN
    DECLARE ep_length DOUBLE;
    DECLARE s_id INT;
    DECLARE updated_rating DOUBLE;
    
    #get the episode_length and series_id
    SELECT episode_length, series_id
    INTO ep_length, s_id
    FROM episodes
    WHERE episode_id = NEW.episode_id;
    
    #a. adjust minutes_played if greater than episode_length
    IF NEW.minutes_played > ep_length THEN
        SET NEW.minutes_played = ep_length;
    END IF;
    
    #b. increase series rating if less than 5.00
    SELECT rating INTO updated_rating
    FROM series
    WHERE series_id = s_id;
    
    IF updated_rating < 5.00 THEN
        UPDATE series
        SET rating = LEAST(5.00, rating+(0.0001 * NEW.minutes_played))
        WHERE series_id = s_id;
    END IF;
END;
//

# Solution 4

DELIMITER //
CREATE PROCEDURE AddEpisode(IN s_id INT,IN s_number tinyint,IN e_number tinyint,IN e_title varchar(128),IN e_length double)
BEGIN
	IF EXISTS (SELECT 1 FROM series WHERE series_id = s_id) AND
    	NOT EXISTS (SELECT 1 FROM episodes WHERE series_id = s_id AND season_number = s_number AND episode_number = e_number) THEN 
        INSERT INTO episodes (series_id, season_number, episode_number, episode_title, episode_length, date_of_release) VALUES
(S_id,s_number,e_number, e_title, e_length, CURRENT_DATE());
    END IF; 
END //

# Solution 5

DELIMITER $$

DROP FUNCTION IF EXISTS GetEpisodeList$$
CREATE FUNCTION GetEpisodeList(s_id INT, s_number INT)
RETURNS TEXT
DETERMINISTIC
BEGIN
    DECLARE ep_list TEXT;

    SELECT GROUP_CONCAT(episode_title ORDER BY episode_number ASC SEPARATOR ', ')
    INTO ep_list
    FROM episodes
    WHERE series_id = s_id AND season_number = s_number;

    RETURN ep_list;
END $$
