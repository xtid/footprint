import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:footprint/model/list_form_data.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:footprint/pages/login.dart';
import 'package:footprint/api/http.dart';
import 'package:footprint/model/category.dart';
import 'package:footprint/model/login_form_data.dart';

import 'package:footprint/utils/md5.dart';
import 'package:footprint/utils/oss_util.dart';

class DioWeb {

  // 格式化提示信息
  static void formatMsg(msg) {
    Fluttertoast.showToast(
      msg: msg,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1
    );
  }

  // 登录过期提示信息
  static bool formatResultData(res, context) {
    final code = res.data['status']['code'];
    if (code == 200) {
      return true;
    } else if (code == 113) {
      formatMsg('登录过期，请重新登录');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Login()),
        (route) => false,
      );
      return false;
    } else {
      formatMsg(res.data['status']['message']);
      return false;
    }
  }

  // 清空本地存储用户信息
  static Future clearUserInfo() async {
    var prefs = await SharedPreferences.getInstance();
    prefs.remove('_id');
    prefs.remove('token');
    prefs.remove('userName');
    prefs.remove('mobile');
    prefs.remove('avatar');
  }

  // 格式化足迹数据
  static List<CategoryDetail> formatFootPrintList (List categoryDetailData) {
    List<CategoryDetail> footprintList = new List<CategoryDetail> ();
    for (var detail in categoryDetailData) {
      CategoryDetail categoryDetailItem = new CategoryDetail(
        detail['_id'],
        detail['category'],
        detail['user']['_id'],
        detail['categoryDetailName'],
        detail['content'],
        detail['created'],
        detail['dateTime'],
        detail['imageUrl'],
        detail['localtion'],
        detail['modified'],
        detail['user']['userName'],
        detail['user']['avatar']
      );
      footprintList.add(categoryDetailItem);
    }
    return footprintList;
  }

  // 获取分类信息
  static Future<List<CategoryModel>> getCategoryData() async {
    List<CategoryModel> categories = new List<CategoryModel> ();
    try {
      var prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('token');
      var userId = prefs.getString('_id');
      var res;
      dio.options.headers['authorization'] = token;
      dio.options.responseType = ResponseType.json;
      if (userId != null && userId != '') {
        res = await dio.get('/category', queryParameters: {
          'userId': userId
        });
      } else {
        res = await dio.get('/empty-category');
      }
      var code = res.data['status']['code'];
      if (code == 200) {
        var categoryData = res.data['data']['data'];
        for (var item in categoryData) {
          List<CategoryDetail> categoryDetail = new List<CategoryDetail> ();
          for (var detail in item['categoryDetail']) {
            CategoryDetail categoryDetailItem = new CategoryDetail(
              detail['_id'],
              detail['category']['_id'],
              detail['user']['_id'],
              detail['categoryDetailName'],
              detail['content'],
              detail['created'],
              detail['dateTime'],
              detail['imageUrl'],
              detail['localtion'],
              detail['modified'],
              detail['user']['userName'],
              detail['user']['avatar']
            );
            categoryDetail.add(categoryDetailItem);
          }
          CategoryModel category = new CategoryModel(item['id'], item['name'], item['key'], categoryDetail);
          categories.add(category);
        }
      } 
      return categories;
    } catch (e) {
      formatMsg('网络错误');
      return categories;
    }
  }

  // 获取验证码
  static Future<String> getVerifyCode() async {
    try {
      dio.options.responseType = ResponseType.json;
      var res = await dio.get('/verify-code');
      if (res.data['status']['code'] == 200 && res.data['data']['code'] != null) {
        return res.data['data']['code'];
      } else {
        formatMsg('网络错误');
        return '';
      }
    } catch (e) {
      formatMsg('网络错误');
      return '';
    }
  }

  // 登录
  static Future<bool> login(LoginFormDataModel loginFormData) async {
    dio.options.responseType = ResponseType.json;
    dio.options.headers['authorization'] = MD5.generateMd5(loginFormData.password);
    try {
      var res = await dio.post('/login', data: {
        'mobile': loginFormData.mobile,
        'verifyCode': loginFormData.verifyCode,
        'invitionCode': loginFormData.invitionCode,
      });
      if (res.data['status']['code'] == 200) {
        // cookie
        // String cookiePath = await Util.getCookiePath();
        // PersistCookieJar cookieJar = new PersistCookieJar(dir: cookiePath);
        // cookieJar.deleteAll();

        // List<Cookie> cookies = new List();
        // cookies.add(new Cookie('token', res.data['data']['token']));
        // cookies.add(new Cookie('userName', res.data['data']['userName']));
        // cookies.add(new Cookie('mobile', res.data['data']['mobile']));
        // cookies.add(new Cookie('avatar', res.data['data']['avatar']));

        // cookieJar.saveFromResponse(Uri.parse('http://192.168.0.102/'), cookies);
        // var b = cookieJar.loadForRequest(Uri.parse('http://192.168.0.102/'));

        // 本地化存储
        var prefs = await SharedPreferences.getInstance();
        prefs.setString('_id', res.data['data']['_id']);
        prefs.setString('token', res.data['data']['token']);
        prefs.setString('userName', res.data['data']['userName']);
        prefs.setString('mobile', res.data['data']['mobile']);
        prefs.setString('avatar', res.data['data']['avatar']);
        return true;
      } else {
        formatMsg(res.data['status']['message']);
        return false;
      }
    } catch (e) {
      formatMsg('网络错误');
      return false;
    }
  }

  // 注销登录
  static Future<bool> loginOut() async {
    try {
      dio.options.responseType = ResponseType.json;
      var prefs = await SharedPreferences.getInstance();
      var mobile = prefs.getString('mobile');
      var res = await dio.post('/login-out', data: {
        'mobile': mobile,
      });
      if (res.data['status']['code'] == 200) {
        // 清空本地化存储
        await clearUserInfo();
        return true;
      } else {
        formatMsg(res.data['status']['message']);
        return false;
      }
    } catch (e) {
      formatMsg('网络错误');
      return false;
    }
  }

  // 获取列表数据
  static Future<List<CategoryDetail>> getFootprintList(String categoryId, int pageNum, bool isUserLogin) async {
    List<CategoryDetail> footprintList = new List<CategoryDetail> ();
    try {
      var prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('token');
      var userId = prefs.getString('_id');
      dio.options.headers['authorization'] = token;
      dio.options.responseType = ResponseType.json;
      var res;
      if (
        userId != null &&
        userId != '' &&
        isUserLogin
      ) {
        res = await dio.get('/footprint', queryParameters: {
          'userId': userId,
          'categoryId': categoryId,
          'pageNum': pageNum
        });
      } else {
        res = await dio.get('/empty-footprint', queryParameters: {
          'pageNum': pageNum
        });
      }
      var code = res.data['status']['code'];
      if (code == 200) {
        var categoryDetailData = res.data['data'];
        footprintList = formatFootPrintList(categoryDetailData['data']);
      } else {
        if (code == 113) {
          if (userId != '' && userId != null) {
            await clearUserInfo();
            formatMsg(res.data['status']['message']);
          } 
          res = await dio.get('/empty-footprint', queryParameters: {
            'pageNum': pageNum
          });
          var code = res.data['status']['code'];
          if (code == 200) {
            var categoryDetailData = res.data['data'];
            footprintList = formatFootPrintList(categoryDetailData['data']);
          }
        }
      }
      return footprintList;
    } catch (e) {
      formatMsg('网络错误');
      return footprintList;
    }
  }

  // 上传图片至阿里云
  static Future<String> upload(PickedFile image) async {
    var baseUrl = 'http://footprintpic.oss-cn-hangzhou.aliyuncs.com/';
    var fileName = OssUtil.instance.getImageName(image.path);
    dio.options.responseType = ResponseType.plain;
    FormData formdata = FormData.fromMap({
      'Filename': fileName,
      'key': 'images/' + fileName,
      'policy': OssUtil.policy,
      'OSSAccessKeyId': '',
      'success_action_status': '200',
      'signature': OssUtil.instance.getSignature(''),
      'file': MultipartFile.fromFileSync(image.path, filename:OssUtil.instance.getImageNameByPath(image.path))
      });
    var response = await dio.post(baseUrl, data: formdata);
    if (response.statusCode == 200) {
      return baseUrl + 'images/' + fileName;
    } else {
      formatMsg('上传图片失败，请稍候再试');
      return '';
    }
  }

  // 编辑具体分类选项
  static Future<bool> editCategoryDetail(ListFormData listFormData, CategoryDetail listItem) async {
    try {
      dio.options.responseType = ResponseType.json;
      var res = await dio.post('/edit-list', data: {
        '_id': listItem.id,
        'id': listItem.userId,
        'categoryId': listItem.categoryId,
        'content': listFormData.content,
        'dateTimeStr': listFormData.dateTimeStr,
        'imageUrl': listFormData.imageUrl,
        'locationStr': listFormData.locationStr
      });
      if (res.data['status']['code'] == 200) {
        return true;
      } else {
        formatMsg(res.data['status']['message']);
        return false;
      }
    } catch (e) {
      formatMsg('网络错误');
      return false;
    }
  }

  // 修改账户信息
  static Future<bool> editUserInfo(data, type, context) async {
    try {
      var prefs = await SharedPreferences.getInstance();
      var id = prefs.getString('_id');
      var token = prefs.getString('token');
      
      dio.options.headers['authorization'] = token;
      dio.options.responseType = ResponseType.json;

      var res = await dio.post('/edit-user', data: {
        'type': type,
        'id': id,
        'data': data
      });
      final formatResultFlag = formatResultData(res, context);
      return formatResultFlag;
    } catch (e) {
      formatMsg('网络错误');
      return false;
    }
  } 

  // 修改密码信息
  static Future<bool> editUserPdInfo(oldPd, newPd, context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('_id');
      final token = prefs.getString('token');
      
      dio.options.headers['authorization'] = token;
      dio.options.responseType = ResponseType.json;

      final res = await dio.post('/user-info', data: {
        'id': id,
        'oldData': MD5.generateMd5(oldPd),
        'newData': MD5.generateMd5(newPd)
      });
      final formatResultFlag = formatResultData(res, context);
      return formatResultFlag;
    } catch (e) {
      formatMsg('网络错误');
      return false;
    }
  } 

}