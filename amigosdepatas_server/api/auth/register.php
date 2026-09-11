<?php
require __DIR__ . '/../../src/bootstrap.php';
method('POST');
$d = body();
$name = field($d, 'name', 150);
$email = emailField($d);
$phone = field($d, 'phone', 40);
$password = field($d, 'password', 72);
if (strlen($password) < 8) respond(['success'=>false,'message'=>'Use uma senha com pelo menos 8 caracteres.']);
try {
    $q = db()->prepare('INSERT INTO users (name,email,phone,password_hash) VALUES (:name,:email,:phone,:hash)');
    $q->execute(['name'=>$name,'email'=>$email,'phone'=>$phone,'hash'=>password_hash($password, PASSWORD_DEFAULT)]);
} catch (PDOException $e) {
    if ($e->getCode() === '23505') respond(['success'=>false,'message'=>'E-mail já cadastrado.']);
    throw $e;
}
respond(['success'=>true,'message'=>'Cadastro realizado com sucesso.']);
