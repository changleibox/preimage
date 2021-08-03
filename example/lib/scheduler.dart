/*
 * Copyright (c) 2021 CHANGLEI. All rights reserved.
 */

import 'dart:ui';

import 'package:flutter/scheduler.dart';

/// Created by changlei on 2021/8/3.
///
/// 监听[SchedulerBinding.instance.addPostFrameCallback]
class Scheduler {
  /// 构造函数
  Scheduler.postFrame(VoidCallback? callback) {
    if (SchedulerBinding.instance!.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance!.addPostFrameCallback((Duration duration) {
        if (_canceled) {
          return;
        }
        callback?.call();
      });
    } else {
      callback?.call();
    }
  }

  bool _canceled = false;

  /// 取消监听
  void cancel() {
    _canceled = true;
  }
}
