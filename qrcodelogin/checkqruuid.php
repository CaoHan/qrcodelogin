<?php
/**
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

$sql = "select * from qrcodelogin where qruuid='" . $qruuid . "'";
$result = $mysqli->query($sql)->fetch_array();

if ($result === false) {
    echo $mysqli->error;
    echo $mysqli->errno;
}

$mysqli->close();

if (!is_null($result['user_id']))
    $arr = ['code' => 1, 'msg' => '登录成功', 'data' => $result];
else
    $arr = ['code' => 500, 'msg' => 'qruuid暂时未被绑定','data'=>$qruuid];

echo json_encode($arr);
exit();
?>