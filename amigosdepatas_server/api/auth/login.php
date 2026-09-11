<?php
require __DIR__ . '/../../src/bootstrap.php';
method('POST');
$d = body();
$email = emailField($d);
$password = field($d, 'password', 72);
$q = db()->prepare('SELECT id,name,email,phone,password_hash FROM users WHERE email = :email');
$q->execute(['email'=>$email]);
$user = $q->fetch();
if (!$user || !password_verify($password, $user['password_hash']))
    respond(['success'=>false,'message'=>'E-mail ou senha incorretos.','user'=>null]);
unset($user['password_hash']);
respond(['success'=>true,'message'=>'Login realizado.','user'=>$user]);
