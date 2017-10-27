<?php
/**
 * App端扫描二维码 获得qruuid
 * 然后请求这个接口  二维码的qruuid和用户绑定并把用户信息传入(token或者info什么的 具体看需求)
 *
 * Created by PhpStorm.
 * User: caohan
 * Date: 2017/10/15
 * Time: 下午3:17
 */


require('config.php');

$mysqli = new mysqli($db_host, $db_user, $db_pwd, $db_name);
if (mysqli_connect_error())
    echo mysqli_connect_error();
$mysqli->set_charset("utf8");

$qruuid = $_GET['qruuid'];
$user_id = $_GET['user_id'];
$user_token = $_GET['user_token'];

$sql = "update qrcodelogin set user_id='" . $user_id . "',user_token='" . $user_token . "' where qruuid='" . $qruuid . "'";
$result = $mysqli->query($sql);

if ($result === false) {
    echo $mysqli->error;
    echo $mysqli->errno;
}

$mysqli->close();
$arr = ['code' => 1, 'msg' => '绑定成功'];
echo json_encode($arr);
exit();
