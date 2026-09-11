<?php
require __DIR__ . '/../../src/bootstrap.php';
method('GET');
$stats = rows('SELECT (SELECT count(*) FROM animals) AS animals_count,
 (SELECT count(*) FROM campaigns WHERE active = 1) AS campaigns_count,
 (SELECT count(*) FROM news) AS news_count,
 (SELECT count(*) FROM adoption_requests) AS requests_count')[0];
respond(['success'=>true,'data'=>[
 'settings'=>rows('SELECT * FROM settings WHERE id = 1')[0],
 'stats'=>$stats,
 'featured_animals'=>rows('SELECT * FROM animals WHERE featured = 1 ORDER BY id DESC LIMIT 6'),
 'featured_campaigns'=>rows('SELECT * FROM campaigns WHERE featured = 1 AND active = 1 ORDER BY id DESC LIMIT 6'),
 'latest_news'=>rows('SELECT * FROM news ORDER BY published_at DESC, id DESC LIMIT 5')
]]);
