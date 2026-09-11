<?php
require __DIR__ . '/../../src/bootstrap.php';
method('GET');
respond(['success'=>true,'item'=>rows('SELECT * FROM settings WHERE id = 1')[0] ?? null]);
