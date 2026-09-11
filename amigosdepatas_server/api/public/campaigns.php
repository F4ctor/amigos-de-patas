<?php
require __DIR__ . '/../../src/bootstrap.php';
method('GET');
respond(['success'=>true,'items'=>rows('SELECT * FROM campaigns WHERE active = 1 ORDER BY id DESC')]);
