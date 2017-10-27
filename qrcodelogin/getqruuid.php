<?php
/**
 * 用于前端获取qruuid(二维码唯一ID)使用
 *
 * Created by PhpStorm.
 * User: caohan
 * Date: 2017/10/15
 * Time: 下午2:59
 */
require('config.php');

$mysqli = new mysqli($db_host, $db_user, $db_pwd, $db_name);
if (mysqli_connect_error())
    echo mysqli_connect_error();
$mysqli->set_charset("utf8");

//生成随机的UUID 用于二维码显示的内容 和 绑定用
$qruuid = substr(md5(uniqid(mt_rand(), true)), 0, 15);//生成uuid

$sql = "insert into qrcodelogin (qruuid) values ('". $qruuid ."')";
$result = $mysqli->query($sql);


if($result === false){
    echo $mysqli->error;
    echo $mysqli->errno;
}

$mysqli->close();

$arr = ['code'=>1, 'msg' => '生成qruuid成功','data'=>$qruuid];
echo json_encode($arr);
exit();
