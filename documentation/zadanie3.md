# Databázové systémy
## Zadanie č.3
###### Autor: Marek Čederle

Poznámky ku zadaniu:
- V endpointe č.2 sa mi líšia trocha formát pre `avg` a `diff` pretože keď som to nepretypoval do stringu tak mi to dávalo ako desatinné čísla a nie ako intervali. Takže mám na začiatku niekedy `0` a na konci niekedy pár núl navyše.
- Ostatné endpointy sú podľa testera správne.

### Query pre endpoint č.1
HTTP GET REQUEST:
`/v3/users/:user_id/badge_history`
```sql
SELECT
	final_table.id,
	final_table.title,
	final_table.type,
	TO_CHAR(final_table.created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH') AS created_at,
	CEILING(ROW_NUMBER() OVER () / 2.0) AS position
FROM
(
	SELECT
		prev_next.*,
		CASE
			WHEN prev_next.type = 'post' AND prev_next.next_type = 'badge' THEN 'THIS'
			WHEN prev_next.type = 'badge' AND prev_next.prev_type = 'post' THEN 'THIS' 
		END marked
	FROM
	(
		SELECT
			p_and_b.*,
			LAG(p_and_b.type) OVER (ORDER BY p_and_b.created_at, p_and_b.id) AS prev_type,
			LEAD(p_and_b.type) OVER (ORDER BY p_and_b.created_at,  p_and_b.id) AS next_type
		FROM
		(
			(
				SELECT
					p.id,
					p.title,
					'post' AS type,
					p.creationdate AS created_at
				FROM users AS u
				JOIN posts AS p ON p.owneruserid = u.id
				WHERE u.id = /*user_id*/
			)
			UNION
			--to iste len s badges
			(
				SELECT
					b.id,
					b.name AS title,
					'badge' AS type,
					b.date AS created_at
				FROM users AS u
				JOIN badges AS b ON b.userid = u.id
				WHERE u.id = /*user_id*/
			)
		) AS p_and_b --posts and badges
	) AS prev_next --previous and next posts types
) AS final_table
WHERE final_table.marked = 'THIS'
ORDER BY final_table.created_at, final_table.id;
```
#### Opis query č.1

Prvý najvnorenejší `SELECT` vyberie všetky príspevky, ktoré patria danému používateľovi. Druhý `SELECT` vyberie všetky odznaky, ktoré patria danému používateľovi. Následne ich spojí do jednej tabuľky `p_and_b`. Ďalší `SELECT` priradí predchádzajúci a nasledujúci typ príspevku k danému príspevku s tým že ich zoradí podľa dátumu vytvorenia (tabuľka `prev_next`). Toto je potrebné na párovanie príspevkov s odznakmi. Daľší `SELECT` označí príspevky, ktoré sú párované s odznakmi (tabuľka `final_table`). Posledný respektíve najviac vonkajší `SELECT` vyberie všetky potrebné parametre, správne naformátuje dátumy a zoradí ich podľa `created_at` a `id` vzostupne. Taktiež priradí pozíciu `position` k príspevkom a odznakom. Toto je v podstate zaobalenie kvôli klauzule `WHERE` pretože potrebujeme označiť iba tie príspevky, ktoré sú párované s odznakmi.

Ukážkový výstup pre user_id = 120
`http://localhost:8000/v3/users/120/badge_history`
```json
{
    "items": [
        {
        "id": 7744,
        "title": "How do I make Firefox remember its window size?",
        "type": "post",
        "created_at": "2009-07-18T05:33:08.597+02",
        "position": 1
        },
        {
        "id": 5453,
        "title": "Student",
        "type": "badge",
        "created_at": "2009-07-18T05:47:30.730+02",
        "position": 1
        },
        {
        "id": 8957,
        "title": null,
        "type": "post",
        "created_at": "2009-07-20T04:27:58.430+02",
        "position": 2
        },
        {
        "id": 6095,
        "title": "Teacher",
        "type": "badge",
        "created_at": "2009-07-20T04:32:30.713+02",
        "position": 2
        },
        {
        "id": 14860,
        "title": "How to remove iso 9660 from USB?",
        "type": "post",
        "created_at": "2009-07-29T05:52:34.903+02",
        "position": 3
        },
    ! JSON POKRACUJE ALE OUTPUT JE VELKY TAKZE TU JE IBA UKAZKA ZO ZACIATKU !
    ...
    ]
}
```

### Query pre endpoint č.2
HTTP GET REQUEST:
`/v3/tags/:tag/comments?count=:count`
```sql
SELECT
	final_tab.id,
	final_tab.title,
	final_tab.displayname,
	final_tab.text,
	TO_CHAR(final_tab.post_created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH') AS post_created_at,
	TO_CHAR(final_tab.created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH') AS created_at,
	COALESCE(final_tab.diff, final_tab.avg) AS diff,
	final_tab.avg
FROM
(
	SELECT
		out_tab.id,
		out_tab.title,
		out_tab.displayname,
		out_tab.text,
		out_tab.post_created_at,
		out_tab.created_at,
		out_tab.diff,
		((out_tab.created_at - out_tab.post_created_at) / out_tab.comment_seq_num) AS avg
	FROM
	(
		SELECT
			count_tab.id,
			count_tab.title,
			count_tab.displayname,
			count_tab.text,
			count_tab.post_created_at,
			count_tab.created_at,
			count_tab.previous_comment_date,
			(count_tab.created_at - count_tab.previous_comment_date) AS diff,
			ROW_NUMBER() OVER (PARTITION BY count_tab.id) AS comment_seq_num
		FROM
		(
			SELECT
				in_tab.id,
				in_tab.title,
				u.displayname,
				c.text,
				in_tab.creationdate AS post_created_at,
				c.creationdate AS created_at,
				LAG(c.creationdate) OVER (PARTITION BY c.postid ORDER BY c.creationdate) AS previous_comment_date,
				COUNT(*) OVER (PARTITION BY in_tab.id) AS comment_count
			FROM
			(
				SELECT DISTINCT
					posts.id,
					posts.title,
					posts.creationdate
				FROM posts
				JOIN post_tags AS pt ON posts.id = pt.post_id
				JOIN tags AS t ON pt.tag_id = t.id
				WHERE t.tagname = '/*tag*/'
			) AS in_tab
			JOIN comments AS c ON c.postid = in_tab.id
			LEFT JOIN users AS u ON u.id = c.userid --LEFT JOIN lebo inak mi jeden zaznam zmizol
		) AS count_tab
		WHERE count_tab.comment_count > /*count*/
	) AS out_tab
) AS final_tab
GROUP BY
	final_tab.id,
	final_tab.title,
	final_tab.displayname,
	final_tab.text,
	final_tab.post_created_at,
	final_tab.created_at,
	final_tab.diff,
	final_tab.avg
ORDER BY final_tab.id, final_tab.created_at ASC;
```
#### Opis query č.2

Najviac vnútorný `SELECT` vyberie všetky príspevky, ktoré obsahujú daný tag (tabuľka `in_tab`). Nasledujúci `SELECT` vyberie všetky komentáre `comments`, ktoré patria k príspevku s daným tagom a zároveň ich spojí s použávateľmi `users` (tabuľka `count_tab`). Následne im priradí `previous_comment_date` čo predstavuje dátum predchádzajúceho komentára a taktiež ku každému príspevku priradí počet komentárov `comment_count` (tabuľka `count_tab`). Ďalší `SELECT` vyberie všetky komentáre, ktoré majú viac ako `count` komentárov (tabuľka `out_tab`, je to zaobalenie kvôli tomu že potrebujeme použiť `previous_comment_date`). Následne im priradí `diff` čo predstavuje rozdiel medzi dátumom vytvorenia komentára a dátumom vytvorenia predchádzajúceho komentára (tabuľka `out_tab`). Ku koncu sa vypočíta priemerný čas medzi komentármi `avg` (tabuľka `final_tab`). Posledný respektíve najviac vonkajší `SELECT` vyberie všetky potrebné parametre, správne naformátuje dátumy a nahradí `[null]` hodnoty v stĺpci diff za priemer `avg` (je to v podstate zaobalenie kvôli tomu nahrádzaniu hodnôt pretože prvý príspevok nemá predchádzajúci komentár). Výsledok zoradí podľa `id` a `created_at` vzostupne.

Ukážkový výstup pre tag = networking a count = 40
`http://localhost:8000/v3/tags/networking/comments?count=40`
```json
{
    "items": [
        {
            "post_id": 1034137,
            "title": "Did I just get hacked?",
            "displayname": "Jonno",
            "text": "Yeah that doesn't look too good. I'm not an expert in Linux by any means, but somethings definitely tried to execute on there. I'm not quite sure how though as it looks like it attempted to log in as root and failed. Are there any other logs in your auth.log? Any other means of remote admin? I've seen Mac's with VNC server enabled get hacked before via that, although this looks like an SSH attempt. Looks like the IPs it was downloading from are hosted in China somewhere.",
            "post_created_at": "2016-02-01T11:21:48.690+01",
            "created_at": "2016-02-01T11:25:02.610+01",
            "diff": "0:03:13.920000",
            "avg": "0:03:13.920000"
        },
        {
            "post_id": 1034137,
            "title": "Did I just get hacked?",
            "displayname": "David Schwartz",
            "text": "The attack actually came from China.",
            "post_created_at": "2016-02-01T11:21:48.690+01",
            "created_at": "2016-02-01T11:30:45.310+01",
            "diff": "0:05:42.700000",
            "avg": "0:04:28.310000"
        },
        {
            "post_id": 1034137,
            "title": "Did I just get hacked?",
            "displayname": "vaid",
            "text": "Yes but what is a Microsoft owned IP doing trying to breach a device across the internet?",
            "post_created_at": "2016-02-01T11:21:48.690+01",
            "created_at": "2016-02-01T11:37:58.037+01",
            "diff": "0:07:12.727000",
            "avg": "0:05:23.115667"
    },
    ! JSON POKRACUJE ALE OUTPUT JE PRILIS VELKY TAKZE TU JE IBA UKAZKA ZO ZACIATKU !
    ...
    ]
}
```

### Query pre endpoint č.3
HTTP GET REQUEST:
`/v3/tags/:tagname/comments/:position?limit=:limit`
```sql
SELECT
    final_table.id,
    final_table.displayname,
    final_table.body,
    final_table.text,
    final_table.score,
    final_table.position
FROM
(
	/* zaobalenie kvoli where clause aby som moohl pouzit s position */
	SELECT
		c.id,
		u.displayname,
		p.body,
		c.text,
		c.score,
		p.post_tag_rank,
		ROW_NUMBER() OVER (PARTITION BY p.post_tag_rank ORDER BY p.creationdate, c.creationdate ASC) AS position
	FROM comments AS c
	JOIN users AS u ON u.id = c.userid
	JOIN
	(
		/* tato habadura je pretoze row number ignoruje distinct ak to je v tej istej "urovni" */
		SELECT
			ranked_posts.id,
			ranked_posts.body,
			ranked_posts.creationdate, /* iba kvoli order by */
			ROW_NUMBER() OVER (ORDER BY ranked_posts.creationdate ASC) AS post_tag_rank
		FROM
		(
			SELECT DISTINCT
				posts.id,
				posts.body,
				posts.creationdate /* iba kvoli order by */
			FROM posts
			JOIN post_tags AS pt ON posts.id = pt.post_id
			JOIN tags AS t ON pt.tag_id = t.id
			WHERE t.tagname = '/*tagname*/'
			ORDER BY posts.creationdate ASC
		) AS ranked_posts
		ORDER BY ranked_posts.creationdate
	) AS p ON p.id = c.postid
	ORDER BY p.creationdate, c.creationdate ASC
) AS final_table
WHERE position=/*position*/
LIMIT /*limit*/;
```
#### Opis query č.3

Najviac vnútorný `SELECT` vyberie všetky príspevky, ktoré obsahujú daný tag a zoradí ich podľa `creationdate` vzostupne (tabuľka `ranked_posts`). Následne im priradí `post_tag_rank` čo predstavuje poradové číslo postu (tabuľka `p`). Ďalší `SELECT` vyberie všetky komentáre, ktoré patria k príspevku s daným tagom a zoradí ich podľa `creationdate` vzostupne. Následne im priradí `position` čo predstavuje poradové číslo komentára v rámci príspevku (tabuľka `final_table`). Posledný respektíve najviac vonkajší `SELECT` je iba zaobalenie kvôli `WHERE` klauzule, ktorá nejde použiť pri `ROW_NUMBER()` a ten nám vráti vlastne komentáre na `position` (k-tej) pozícii v rámci príspevku s limitom `limit`.

Ukážkový výstup pre tagname = linux, position = 2 a limit = 1
`http://localhost:8000/v3/tags/linux/comments/2?limit=1`
```json
{
    "items": [
        {
            "id": 745427,
            "displayname": "Oliver Salzburg",
            "body": "<p>I am running Kubuntu Hardy Heron, with a dual monitor setup, and have VirtualBox on it running Windows XP in seamless mode.</p>\n\n<p>My problem is, I can't get VirtualBox to extend to the second monitor. \nHow can this be achieved?</p>\n",
            "text": "http://ubuntuforums.org/showthread.php?t=433359",
            "score": 0,
            "position": 2
        }
    ]
}
```

### Query pre endpoint č.4
HTTP GET REQUEST:
`/v3/posts/:postid?limit=:limit`
```sql
SELECT
    u.displayname,
    p.body,
    TO_CHAR(p.creationdate, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH') AS created_at
FROM posts AS p
JOIN users AS u ON u.id = p.owneruserid
WHERE p.id = /*post_id*/ OR p.parentid = /*post_id*/
ORDER BY created_at ASC
LIMIT /*limit*/;
```
#### Opis query č.4
`SELECT` vyberie požadované parametre. Následne spojím tabuľky `posts` a `users`. Potom vyberiem prispevkok, ktorý ma dané `postid` a následne podľa `parentid` vyberiem príspevky, ktoré sú súčasťou toho vlákna. Výsledok zoradím podľa `created_at` vzostupne a vyberiem prvých `limit` záznamov.

Ukážkový výstup pre postid = 2154 a limit = 2
`http://localhost:8000/v3/posts/2154?limit=2`
```json
{
    "items": [
        {
            "displayname": "Eugene M",
            "body": "<p>So, I'm a technology guy and sometimes I have to troubleshoot a home network, including my own. I make sure the wires are in securely and that the lights suggest there's an actual internet connection. Usually after that point I just reset the router( and possibly the cable modem) and that fixes things most of the time.</p>\n\n<p>The problem is I'd like to know what sort of issue I could possibly be fixing by resetting the router.</p>\n\n<p>EDIT: Just to clarify, I was speaking more about reset as in turning the router off and on. Still, any information about a hard reset(paperclip in the hole) is useful. So the more accurate term would probably be restarting </p>\n\n<p>Also, personally I usually have to deal with D-Link or Linksys home routers. I generally only bother messing around with stuff if I can't make a connection to the internet at all.</p>\n",
            "created_at": "2009-07-15T14:51:57.340+02"
        },
        {
            "displayname": "Ólafur Waage",
            "body": "<p>Every router has it's original firmware stored somewhere on it.</p>\n\n<p>When you reset the router you overwrite the current firmware and config with the original one. What usually is fixing the problem is that the config is overwritten with the original one. But in some cases you have an updated router that isn't working for some reason.</p>\n",
            "created_at": "2009-07-15T14:54:48.507+02"
        }
    ]
}
```