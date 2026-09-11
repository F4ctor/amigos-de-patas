<?php
require __DIR__ . '/../../src/bootstrap.php';
method('GET');
respond(['success'=>true,'items'=>rows('SELECT * FROM animals  ORDER BY id DESC')]);
