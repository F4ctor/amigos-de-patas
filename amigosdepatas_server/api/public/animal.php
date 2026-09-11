<?php
require __DIR__ . '/../../src/bootstrap.php';
method('GET');
$id = filter_var($_GET['id'] ?? null, FILTER_VALIDATE_INT, ['options'=>['min_range'=>1]]);
if ($id === false) respond(['success'=>false,'item'=>null,'message'=>'ID inválido.'], 400);
$q = db()->prepare('SELECT * FROM animals WHERE id = :id');
$q->execute(['id'=>$id]);
$item = $q->fetch();
respond(['success'=>(bool)$item,'item'=>$item ?: null]);
