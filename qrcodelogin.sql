/*
 Navicat Premium Data Transfer

 Source Server         : 虚拟机DB
 Source Server Type    : MySQL
 Source Server Version : 50636
 Source Host           : 172.10.10.199:3306
 Source Schema         : test


*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for qrcodelogin
-- ----------------------------
DROP TABLE IF EXISTS `qrcodelogin`;
CREATE TABLE `qrcodelogin` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `qruuid` varchar(15) NOT NULL DEFAULT '',
  `user_id` int(11) DEFAULT NULL,
  `user_token` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;
