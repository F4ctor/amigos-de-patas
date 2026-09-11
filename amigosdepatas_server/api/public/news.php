<?php
require __DIR__ . '/../../src/bootstrap.php';
method('GET');
respond(['success'=>true,'items'=>rows('SELECT * FROM news  ORDER BY published_at DESC, id DESC')]);
