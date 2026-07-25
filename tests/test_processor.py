#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
OPPO 主题处理核心逻辑测试

运行方式:
    python3 tests/test_processor.py
"""

import os
import sys
import shutil
import tempfile
import zipfile
import unittest

# 将项目根目录加入路径以导入 processor
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'OPPOThemeTool', 'Python'))
import processor


class TestThemeProcessor(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.theme_dir = os.path.join(self.temp_dir, 'MyTheme')
        os.makedirs(self.theme_dir)

        # 创建 themeInfo.xml
        theme_info = """<?xml version="1.0" encoding="utf-8"?>
<Theme>
    <EditorVersion>12001000</EditorVersion>
    <Summary>Test Theme</Summary>
    <VersionName>v1</VersionName>
</Theme>
"""
        with open(os.path.join(self.theme_dir, 'themeInfo.xml'), 'w', encoding='utf-8') as f:
            f.write(theme_info)

        # 创建 picture 目录及文件
        picture_dir = os.path.join(self.theme_dir, 'picture')
        os.makedirs(picture_dir)
        with open(os.path.join(picture_dir, 'wallpaper.jpg'), 'w') as f:
            f.write('fake image')

        # 创建一个会被 zip 压缩的子文件夹，确保解包时有 zip 文件可解压
        extra_dir = os.path.join(self.theme_dir, 'icons')
        os.makedirs(extra_dir)
        with open(os.path.join(extra_dir, 'icon.png'), 'w') as f:
            f.write('fake icon')

    def tearDown(self):
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_is_zip_file(self):
        zip_path = os.path.join(self.temp_dir, 'test.zip')
        with zipfile.ZipFile(zip_path, 'w') as zf:
            zf.writestr('test.txt', 'hello')
        self.assertTrue(processor.is_zip_file(zip_path))

        txt_path = os.path.join(self.temp_dir, 'test.txt')
        with open(txt_path, 'w') as f:
            f.write('hello')
        self.assertFalse(processor.is_zip_file(txt_path))

    def test_get_output_folder_name(self):
        name = processor.get_output_folder_name(self.theme_dir)
        self.assertEqual(name, '12001TestTheme')

    def test_pack_theme(self):
        result = processor.pack_theme(self.theme_dir)
        self.assertTrue(result['success'], result.get('error'))
        self.assertTrue(os.path.exists(result['output_file']))
        self.assertTrue(result['output_file'].endswith('.theme'))

    def test_unpack_theme(self):
        # 先打包
        pack_result = processor.pack_theme(self.theme_dir)
        self.assertTrue(pack_result['success'])

        # 再解包
        output_dir = os.path.join(self.temp_dir, 'unpacked')
        os.makedirs(output_dir)
        unpack_result = processor.unpack_theme(pack_result['output_file'], output_dir)
        self.assertTrue(unpack_result['success'], unpack_result.get('error'))
        self.assertTrue(os.path.exists(unpack_result['output_folder']))


if __name__ == '__main__':
    unittest.main()
