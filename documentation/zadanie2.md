# Databázové systémy
## Zadanie č.2
###### Autor: Marek Čederle

Poznámky ku zadaniu:
- Moje celé zadanie nemám otestované na testery pretože mi tester stále vyhadzoval `failed`. Tento problém bol riešený na MS Teams a bola uznaná chyba na strane testera.
- V časovom formáte sa moje riešenie nezhoduje s príkladami zo zadanie pretože v zadaní sú niekde uvedené minúty a niekde nie sú a taktiež niekde sú uvedené desatinné čísla na viacej miest. Toto bolo tiež povedané na MS Teams že ide o chybu testera.
- Výsledky z endpointu č.3 sa nezhodujú s príkladom so zadania. Myslím že to je zle počítané v príkladoch.
- Endpointy č.4 a č.5 sú implementované v jednom súbore pretože majú v podstate rovnaký REQUEST a líšia sa iba voliteľnými parametrami.

### Query pre endpoint č.1
HTTP GET REQUEST:
`/v2/posts/:post_id/users`
```sql
SELECT DISTINCT
	u.id,
	u.reputation,
	TO_CHAR(u.creationdate, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH:TZM'),
	u.displayname,
	TO_CHAR(u.lastaccessdate, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH:TZM'),
	u.websiteurl,
	u.location,
	u.aboutme,
	u.views,
	u.upvotes,
	u.downvotes,
	u.profileimageurl,
	u.age,
	u.accountid,
	c.creationdate
FROM users AS u
JOIN comments c ON u.id = c.userid
JOIN posts p ON c.postid = p.id
WHERE p.id = --POST ID--
ORDER BY c.creationdate DESC;
```
#### Opis query č.1

Zoberiem všetky parametre pre používateľa jednotlivo kvôli formátovania času. Následne prepojím tabulky `users`, `comments` a `posts` pomocou ich primárnych a cudzích kľúčov aby som získal všetkých používateľov, ktorí komentovali príspevok so zadaným ID. Následne ich zoradím podľa dátumu vytvorenia komentára.

Ukážkový výstup pre ID 1819157
`http://localhost:8000/v2/posts/1819157/users`
```json
{
    "items": [
        {
            "id": 1866388,
            "reputation": 1,
            "creationdate": "2023-12-01T00:05:24.337+01:00",
            "displayname": "TomR.",
            "lastaccessdate": "2023-12-03T06:18:19.607+01:00",
            "websiteurl": null,
            "location": null,
            "aboutme": null,
            "views": 1,
            "upvotes": 0,
            "downvotes": 0,
            "profileimageurl": null,
            "age": null,
            "accountid": 30035903
        }
    ]
}
```

### Query pre endpoint č.2
HTTP GET REQUEST:
`/v2/users/:user_id/friends`
```sql
SELECT DISTINCT
	u.id,
	u.reputation,
	TO_CHAR(u.creationdate, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH:TZM'),
	u.displayname,
	TO_CHAR(u.lastaccessdate, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH:TZM'),
	u.websiteurl,
	u.location,
	u.aboutme,
	u.views,
	u.upvotes,
	u.downvotes,
	u.profileimageurl,
	u.age,
	u.accountid,
	u.creationdate
FROM users AS u
JOIN comments c ON u.id = c.userid
JOIN
(
	SELECT c.postid AS in_post_id
	FROM posts AS p
	JOIN comments AS c ON p.id=c.postid
	WHERE c.userid = --USER ID--
	
	UNION
	
	SELECT p.id AS in_post_id
	FROM posts AS p
	WHERE p.owneruserid = --USER ID--
) AS created_plus_commented ON c.postid=created_plus_commented.in_post_id
ORDER BY u.creationdate ASC;
```
#### Opis query č.2

Vo vonkajšom `SELECT` zase zoberiem jednotlivo parametre kvôli formátovaniu času. V `JOIN()` mám dve sub-queries. Prvá sub-query vyberie všetky príspevky, na ktorých komentoval používateľ so zadaným ID. Druhá sub-query vyberie všetky príspevky, ktoré vytvoril používateľ so zadaným ID. Potom urobím ich zjednotenie s tým že sa mi automatický vymažú duplikáty (vlastnosť UNION). Následne prepojím túto tabuľku s tabuľkami `comments` a `users` pomocou ich primárnych a cudzích kľúčov. Tým získam všetkých používateľov, ktorí komentovali na príspevkoch používateľa so zadaným ID, ktoré on vytvoril alebo na ktorých on komentoval. Nakoniec ich zoradím podľa toho, kto bol zaregistrovaný skorej.

Ukážkový výstup pre ID 1819157
`http://localhost:8000/v2/users/1076348/friends`
```json
{
    "items": [
        {
            "id": 482362,
            "reputation": 10581,
            "creationdate": "2015-08-11T17:42:36.267+02:00",
            "displayname": "DrZoo",
            "lastaccessdate": "2023-12-03T06:41:11.750+01:00",
            "websiteurl": null,
            "location": null,
            "aboutme": null,
            "views": 1442,
            "upvotes": 555,
            "downvotes": 46,
            "profileimageurl": null,
            "age": null,
            "accountid": 2968677
        },
        {
            "id": 1076348,
            "reputation": 1,
            "creationdate": "2019-08-15T16:00:28.473+02:00",
            "displayname": "Richard",
            "lastaccessdate": "2019-09-10T16:57:48.527+02:00",
            "websiteurl": null,
            "location": null,
            "aboutme": null,
            "views": 0,
            "upvotes": 0,
            "downvotes": 0,
            "profileimageurl": null,
            "age": null,
            "accountid": 16514661
        }
    ]
}
```

### Query pre endpoint č.3
HTTP GET REQUEST:
`/v2/tags/:tagname/stats`
```sql
SELECT 
	CASE all_p.day_of_week
	   WHEN 1 THEN 'monday'
	   WHEN 2 THEN 'tuesday'
	   WHEN 3 THEN 'wednesday'
	   WHEN 4 THEN 'thursday'
	   WHEN 5 THEN 'friday'
	   WHEN 6 THEN 'saturday'
	   ELSE 'sunday'
	END AS day_of_week,
	ROUND(CAST(tagged.tagged_posts::float / all_p.all_posts * 100 AS NUMERIC), 2) AS percentage
FROM 
(
	SELECT DISTINCT
		COUNT(p.id) AS tagged_posts,
		EXTRACT(ISODOW FROM p.creationdate) AS day_of_week
	FROM tags as t
	JOIN post_tags as pt ON pt.tag_id = t.id
	JOIN posts as p ON p.id = pt.post_id
	WHERE t.tagname = --'TAG NAME'--
	GROUP BY day_of_week
	ORDER BY day_of_week
) AS tagged
JOIN
(
	SELECT DISTINCT
		COUNT(p.id) AS all_posts,
		EXTRACT(ISODOW FROM p.creationdate) AS day_of_week
	FROM posts as p 
	GROUP BY day_of_week
	ORDER BY day_of_week
) AS all_p
ON tagged.day_of_week = all_p.day_of_week;
```
#### Opis query č.3

Vonkajší `SELECT` slúži na to aby pretvoril číselný výstup, ktorý vracia funkcia ISODOW na názvy dní v týždni a na vypísanie podielu v percentách. Tabuľka `tagged` obsahuje počet príspevkov s daným tagom v jednotlivé dni v týždni. Tabuľka `all_p` obsahuje počet všetkých príspevkov v jednotlivé dni v týždni. Nakoniec ich prepojím pomocou dňa v týždni a vypočítam podiel v percentách.

Ukážkový výstup pre tag "linux"
`http://localhost:8000/v2/tags/linux/stats`
```json
{
    "result": {
        "monday": 4.71,
        "tuesday": 4.69,
        "wednesday": 4.63,
        "thursday": 4.57,
        "friday": 4.67,
        "saturday": 4.98,
        "sunday": 4.88
    }
}
```

### Query pre endpoint č.4
HTTP GET REQUEST:
`/v2/posts/?duration=:duration_in_minutes&limit=:limit`
```sql
SELECT 
    p.id,
    TO_CHAR(p.creationdate, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH:TZM'),
    p.viewcount,
    p.lasteditdate,
    TO_CHAR(p.lastactivitydate, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH:TZM'),
    p.title,
    TO_CHAR(p.closeddate, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH:TZM'),
    ROUND(EXTRACT(EPOCH FROM (p.closeddate - p.creationdate)) / 60.0, 2) AS duration
FROM posts AS p
WHERE p.closeddate IS NOT null AND EXTRACT(EPOCH FROM (p.closeddate - p.creationdate)) / 60.0 <= --DURATION--
ORDER BY p.closeddate DESC
LIMIT --LIMIT--;
```
#### Opis query č.4

Vonkajší `SELECT` vyberie dané parametre. Zároveň vypočíta dĺžku trvania príspevku v minútach a to tak, že získa tzv. EPOCH čo je číslo, ktoré predstavuje koľko sekúnd ubehlo od 1.1.1970 a toto číslo vydelí číslom 60 na získanie minút a výsledok zaokrúhly na 2 desatinné miesta. Následne vyberie všetky príspevky, ktoré boli zatvorené a ich `duration` je menší alebo rovný zadanému číslu. Nakoniec záznamy zoradí podľa dátumu zatvorenia a vyberie prvých `limit` príspevkov.

Ukážkový výstup pre duration 5 a limit 2
`http://localhost:8000/v2/posts?duration=5&limit=2`
```json
{
    "items": [
        {
            "id": 1818849,
            "creationdate": "2023-11-30T16:55:32.137+01:00",
            "viewcount": 22924,
            "lasteditdate": null,
            "lastactivitydate": "2023-11-30T16:55:32.137+01:00",
            "title": "Why is my home router address is 10.x.x.x and not 100.x.x.x which is properly reserved and widely accepted for CGNAT?",
            "closeddate": "2023-11-30T16:59:23.560+01:00",
            "duration": 3.86
        },
        {
            "id": 1818386,
            "creationdate": "2023-11-27T18:26:57.617+01:00",
            "viewcount": 19,
            "lasteditdate": null,
            "lastactivitydate": "2023-11-27T18:26:57.617+01:00",
            "title": "Are there any libraries for parsing DWG files with LGPL, MIT, Apache, BSD?",
            "closeddate": "2023-11-27T18:29:18.947+01:00",
            "duration": 2.36
        }
    ]
}
```

### Query pre endpoint č.5
HTTP GET REQUEST:
`/v2/posts?limit=:limit&query=:query`
```sql
SELECT
    p.id,
    TO_CHAR(p.creationdate, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH:TZM'),
    p.viewcount,
    p.lasteditdate,
    TO_CHAR(p.lastactivitydate, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH:TZM'),
    p.title,
    p.body,
    p.answercount,
    TO_CHAR(p.closeddate, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH:TZM'),
    (
        SELECT STRING_AGG(t.tagname, ', ') 
        FROM tags AS t 
        JOIN post_tags AS pt ON pt.tag_id = t.id 
        WHERE pt.post_id = p.id
    ) AS tags
FROM posts AS p
WHERE p.title ILIKE '%--QUERY--%' OR p.body ILIKE '%--QUERY--%'
ORDER BY p.creationdate DESC
LIMIT --LIMIT--;
```
#### Opis query č.5

Vonkajší `SELECT` vyberie dané parametre. Vnutorný `SELECT` vyberie všetky tagy, ktoré sú priradené k príspevku. Následne vyberie všetky príspevky, ktoré obsahujú v názve alebo v tele zadaný reťazec s tým že je použitý case-insensitive regex. Nakoniec záznamy zoradí podľa dátumu vytvorenia a vyberie prvých `limit` príspevkov.

Ukážkový výstup pre query "linux" a limit 1
`http://localhost:8000/v2/posts?limit=1&query=linux`
```json
{
    "items": [
        {
            "id": 1819160,
            "creationdate": "2023-12-03T05:22:43.587+01:00",
            "viewcount": 7,
            "lasteditdate": null,
            "lastactivitydate": "2023-12-03T05:22:43.587+01:00",
            "title": "Keyboard not working on khali linux",
            "body": "<p>I have recently installed virtualbox on my windows 10 and trying to run Linux Ubuntu and Kali. Everything working on Ubuntu without any issue but when I am running kali it is not taking keyboard(Samsung bluetooth 500) input. Please can anyone help me out here.\nMany thanks in advance!!</p>\n",
            "answercount": 0,
            "closeddate": null,
            "tags": [
                "virtual-machine"
            ]
        }
    ]
}
```
