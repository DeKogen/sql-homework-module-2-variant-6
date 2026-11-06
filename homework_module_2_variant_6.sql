/*
ФИО: Киселев Виталий Дмитриевич

Домашнее задание ко второму модулю
Подготовка к выполнению домашнего задания
Заполните таблицы, созданные в рамках домашнего задания к практическому занятию 1, не менее, чем 5-ю осмысленными записями. Данные возьмите из аналогичных систем в реальной жизни. Заполнение оформите в виде SQL-запросов. 
Вариант 6
Выберите станции (или их идентификаторы, если другой информации нет в таблице), на которых поезда останавливаются в период с 14:00 до 15:00, отсортировав их по комбинации полей: станция (идентификатор) по возрастанию, время прибытия по убыванию.
Сопоставьте дням недели количество поездов, останавливающихся на станции «Москворечье». 
*/

BEGIN;

CREATE SCHEMA railway_v6;
SET LOCAL search_path = railway_v6;

CREATE TABLE stations (
    station_no         integer PRIMARY KEY,
    station_name       varchar(200) NOT NULL CHECK (btrim(station_name) <> ''),
    tariff_zone        smallint NOT NULL CHECK (tariff_zone >= 0),
    parent_station_no  integer REFERENCES stations (station_no),
    CHECK (
        (station_no = 1 AND parent_station_no IS NULL)
        OR
        (station_no > 1 AND parent_station_no IS NOT NULL
                        AND parent_station_no < station_no)
    )
);

CREATE TABLE routes (
    route_id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    start_station_no  integer NOT NULL REFERENCES stations (station_no),
    end_station_no    integer NOT NULL REFERENCES stations (station_no),
    CHECK (start_station_no < end_station_no)
);

CREATE TABLE route_stations (
    route_id            integer NOT NULL REFERENCES routes (route_id) ON DELETE CASCADE,
    station_no          integer NOT NULL REFERENCES stations (station_no),
    arrival_time        time(0),
    arrival_day_offset  smallint NOT NULL DEFAULT 0 CHECK (arrival_day_offset >= 0),
    PRIMARY KEY (route_id, station_no),
    UNIQUE (route_id, arrival_day_offset, arrival_time),
    CHECK (arrival_time IS NULL OR arrival_time < TIME '24:00:00'),
    CHECK (arrival_time IS NOT NULL OR arrival_day_offset = 0)
);

CREATE TABLE route_days (
    route_id  integer NOT NULL REFERENCES routes (route_id) ON DELETE CASCADE,
    weekday   smallint NOT NULL CHECK (weekday BETWEEN 1 AND 7),
    PRIMARY KEY (route_id, weekday)
);

CREATE TABLE zone_fares (
    crossed_zone_count  smallint PRIMARY KEY CHECK (crossed_zone_count >= 0),
    price               numeric(12,2) NOT NULL CHECK (price >= 0 AND price <> 'NaN'::numeric)
);

INSERT INTO stations (station_no, station_name, tariff_zone, parent_station_no)
VALUES
    (1, 'Курьяново', 2, NULL),
    (2, 'Москворечье', 3, 1),
    (3, 'Царицыно', 3, 2),
    (4, 'Покровское', 3, 3),
    (5, 'Красный Строитель', 4, 4);

INSERT INTO routes (start_station_no, end_station_no)
VALUES (1, 5), (1, 5), (1, 5), (1, 5), (1, 5), (1, 5);

INSERT INTO route_stations (route_id, station_no, arrival_time, arrival_day_offset)
VALUES
    (1, 1, '13:52', 0),
    (1, 2, '13:54', 0),
    (1, 3, '13:58', 0),
    (1, 4, '14:02', 0),
    (1, 5, '14:05', 0),
    (2, 1, '14:04', 0),
    (2, 2, '14:06', 0),
    (2, 3, '14:10', 0),
    (2, 4, '14:14', 0),
    (2, 5, '14:17', 0),
    (3, 1, '14:16', 0),
    (3, 2, '14:18', 0),
    (3, 3, '14:22', 0),
    (3, 4, '14:26', 0),
    (3, 5, '14:29', 0),
    (4, 1, '14:40', 0),
    (4, 2, '14:42', 0),
    (4, 3, '14:46', 0),
    (4, 4, '14:50', 0),
    (4, 5, '14:53', 0),
    (5, 1, '14:52', 0),
    (5, 2, '14:54', 0),
    (5, 3, '14:58', 0),
    (5, 4, '15:02', 0),
    (5, 5, '15:05', 0),
    (6, 1, '14:10', 0),
    (6, 2, '14:12', 0),
    (6, 3, '14:16', 0),
    (6, 4, '14:20', 0),
    (6, 5, '14:23', 0);

INSERT INTO route_days (route_id, weekday)
VALUES
    (1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7),
    (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7),
    (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (3, 6), (3, 7),
    (4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (4, 6), (4, 7),
    (5, 1), (5, 2), (5, 3), (5, 4), (5, 5), (5, 6), (5, 7),
    (6, 1), (6, 2), (6, 3), (6, 4), (6, 5);

INSERT INTO zone_fares (crossed_zone_count, price)
VALUES
    (1, 61.00),
    (2, 100.00),
    (3, 139.00),
    (4, 178.00),
    (5, 217.00);

COMMIT;

SELECT
    s.station_name,
    rs.arrival_time
FROM railway_v6.route_stations AS rs
JOIN railway_v6.stations AS s
    ON s.station_no = rs.station_no
WHERE rs.arrival_time BETWEEN TIME '14:00:00' AND TIME '15:00:00'
ORDER BY s.station_name ASC, rs.arrival_time DESC;

WITH weekdays (weekday, weekday_name) AS (
    VALUES
        (1, 'Понедельник'),
        (2, 'Вторник'),
        (3, 'Среда'),
        (4, 'Четверг'),
        (5, 'Пятница'),
        (6, 'Суббота'),
        (7, 'Воскресенье')
),
station_trains AS (
    SELECT
        rs.route_id,
        ((rd.weekday - 1 + rs.arrival_day_offset) % 7) + 1 AS weekday
    FROM railway_v6.route_stations AS rs
    JOIN railway_v6.stations AS s
        ON s.station_no = rs.station_no
    JOIN railway_v6.route_days AS rd
        ON rd.route_id = rs.route_id
    WHERE s.station_name = 'Москворечье'
      AND rs.arrival_time IS NOT NULL
)
SELECT
    w.weekday_name,
    COUNT(DISTINCT st.route_id) AS train_count
FROM weekdays AS w
LEFT JOIN station_trains AS st
    ON st.weekday = w.weekday
GROUP BY w.weekday, w.weekday_name
ORDER BY w.weekday;
