# Pannotate

Spatially guided AI video creation  
基于空间标注的 AI 视频生成工具

---

## Project Website | 项目网站

Website: [pannotate.art](https://pannotate.art)

Pannotate also has an early web prototype that demonstrates the core product concept and workflow.

Pannotate 已经有一个早期网页原型，用于展示产品概念和基础工作流。

---

## Overview | 项目简介

Pannotate is an AI video creation tool designed around visual guidance. Instead of relying only on long text prompts, users can start from an image, mark the image directly, describe the desired motion, and use those combined inputs to guide AI video generation.

Pannotate 是一个围绕“视觉引导”设计的 AI 视频生成工具。它不只是依赖长文字提示词，而是让用户从一张图片开始，直接在图片上进行标注，再配合动作描述，引导 AI 更准确地生成视频。

The long-term goal is to make image-to-video generation more precise, controllable, and creator-friendly.

项目的长期目标是让图生视频变得更加精准、可控，并且更适合创作者使用。

---

## Core Concept | 核心理念

Most image-to-video tools ask users to describe everything in text. This can be limiting when the user wants to control a specific object, direction, region, or movement.

大多数图生视频工具都要求用户用文字描述一切。但当用户想控制某个具体对象、方向、区域或动作时，纯文字往往不够直观。

Pannotate explores a different workflow:

Pannotate 探索的是另一种工作流：

1. Upload or select an image  
   上传或选择一张图片

2. Annotate directly on the image  
   直接在图片上进行标注

3. Use visual marks such as drawing, circles, text, or directional guidance  
   使用画笔、圆圈、文字或方向标记表达意图

4. Add a short motion prompt  
   添加简短的动作描述

5. Generate and organize short video clips  
   生成并整理短视频片段

The intended AI input is not just text. It is a combination of:

AI 接收的输入不只是文字，而是以下信息的组合：

- the original image  
  原始图片

- visual annotations on the image  
  图片上的视觉标注

- a motion description prompt  
  动作描述提示词

This makes the user’s intent more spatially precise.

这样可以让用户的意图在空间位置上表达得更准确。

---

## Current iOS Prototype | 当前 iOS 原型

The current iOS version is a native SwiftUI prototype built for iPhone first.

当前 iOS 版本是一个基于 SwiftUI 构建的原生 iPhone 优先原型。

It focuses on validating the product flow, interface structure, and local prototype interactions before connecting real AI generation services.

当前阶段主要用于验证产品流程、界面结构和本地交互原型，暂未接入真实 AI 生成服务。

---

## Implemented Features | 已实现功能

Current prototype features include:

当前原型已包含以下功能：

- Native SwiftUI iOS interface  
  原生 SwiftUI iOS 界面

- iPhone-first layout  
  iPhone 优先设计

- Projects screen for organizing creative work  
  Projects 页面，用于管理创作项目

- Studio screen for selecting images and preparing generation input  
  Studio 页面，用于选择图片并准备生成输入

- Image selection from the device  
  从设备中选择图片

- Lightweight image adjustment flow  
  简单的图片位置和缩放调整流程

- Motion prompt input  
  动作描述输入

- Local mock video generation flow  
  本地模拟视频生成流程

- Outputs screen for generated clips  
  Outputs 页面，用于展示生成结果

- Sequence screen for arranging clips into a larger video flow  
  Sequence 页面，用于组织多个片段

- Profile and Settings screens  
  Profile 和 Settings 页面

- Light / Dark / System appearance switching  
  浅色 / 深色 / 跟随系统主题切换

- Local project and clip management interactions  
  本地项目和片段管理交互

- TestFlight internal testing setup  
  TestFlight 内部测试配置

---

## Current Status | 当前状态

Pannotate is currently a working local iOS prototype.

Pannotate 目前是一个可以运行的本地 iOS 原型。

The current version is suitable for:

当前版本适合用于：

- testing the native iOS user experience  
  测试原生 iOS 用户体验

- validating the Studio to Outputs workflow  
  验证 Studio 到 Outputs 的生成流程

- testing local mock interactions  
  测试本地模拟交互

- collecting feedback through TestFlight internal testing  
  通过 TestFlight 内部测试收集反馈

The following features are not yet fully implemented:

以下功能尚未完整实现：

- real AI video generation API  
  真实 AI 视频生成 API

- backend services  
  后端服务

- user accounts and authentication  
  用户账号与登录认证

- cloud project storage  
  云端项目存储

- real video playback and export pipeline  
  真实视频播放与导出流程

- production-ready annotation export  
  可用于生产环境的标注导出流程

---

## Tech Stack | 技术栈

- SwiftUI
- Xcode
- iOS Native Development
- App Store Connect
- TestFlight
- GitHub

---

## Repository Structure | 项目结构

The project currently contains:

当前项目主要包含：

- `Pannotate-iOS/`  
  Main native iOS app source code  
  iOS 原生应用主要代码

- `DesignReference/`  
  Design screenshots, product notes, and reference materials  
  设计截图、产品说明和参考资料

- `PROJECT_STATUS.md`  
  Project progress and development status summary  
  项目进度与开发状态总结

- `README.md`  
  Project overview and collaboration documentation  
  项目介绍与协作文档

---

## Development Workflow | 开发协作流程

The project uses GitHub for collaboration.

项目使用 GitHub 进行协作。

Recommended workflow:

推荐流程：

```bash
main        # stable branch
feature/*   # feature branches
```

Suggested process:

建议开发流程：

1. Pull the latest version from `main`  
   从 `main` 拉取最新代码

2. Create a new feature branch  
   创建新的功能分支

3. Make changes locally in Xcode  
   在本地 Xcode 中开发

4. Commit changes with a clear message  
   使用清晰的提交信息进行 commit

5. Push the branch to GitHub  
   推送分支到 GitHub

6. Open a Pull Request  
   创建 Pull Request

7. Review and merge  
   Review 后合并

---

## Roadmap | 路线图

Planned next steps include:

后续计划包括：

- Improve Studio annotation tools  
  优化 Studio 标注工具

- Export annotation data for AI generation  
  导出可供 AI 使用的标注数据

- Connect a real AI video generation API  
  接入真实 AI 视频生成 API

- Add persistent project storage  
  增加项目持久化存储

- Improve clip editing and sequence management  
  优化视频片段编辑与序列管理

- Add real video preview and export  
  增加真实视频预览与导出

- Expand iPadOS support later  
  后续扩展 iPadOS 支持

---

## Product Direction | 产品方向

Pannotate aims to become a creative tool for AI video generation where users can communicate intent visually, not just textually.

Pannotate 希望成为一个让用户不仅通过文字、也能通过视觉标注表达创作意图的 AI 视频生成工具。

The key design principle is:

核心设计原则是：

> Let users show the AI what they mean, directly on the image.  
> 让用户直接在图片上告诉 AI：他们想让哪里发生什么。

---

## Author | 作者

David Woo

---

## License | 许可证

All rights reserved.  
版权所有，保留所有权利。

This project is not open-source. Unauthorized copying, redistribution, commercial use, or reuse of the source code is not permitted without written permission.

本项目暂不开源。未经书面许可，不允许复制、再分发、商用或复用本项目源代码。
