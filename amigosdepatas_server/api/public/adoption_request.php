<?php
require __DIR__ . '/../../src/bootstrap.php';
method('POST');
$d = body();
$id = filter_var($d['animal_id'] ?? null, FILTER_VALIDATE_INT, ['options'=>['min_range'=>1]]);
if ($id === false) respond(['success'=>false,'message'=>'Animal inválido.'], 400);
$params = ['animal_id'=>$id,'full_name'=>field($d,'full_name',150),
 'email'=>emailField($d),'phone'=>field($d,'phone',40),'city'=>field($d,'city',150),
 'message'=>field($d,'message',5000,false)];
try {
 $q = db()->prepare('INSERT INTO adoption_requests (animal_id,full_name,email,phone,city,message)
 VALUES (:animal_id,:full_name,:email,:phone,:city,:message)');
 $q->execute($params);
} catch (PDOException $e) {
 if ($e->getCode() === '23503') respond(['success'=>false,'message'=>'Animal não encontrado.']);
 throw $e;
}
respond(['success'=>true,'message'=>'Pedido de adoção enviado com sucesso.']);
