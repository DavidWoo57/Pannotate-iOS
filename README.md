# Pannotate

Spatially guided AI video creation  
基于空间标注的 AI 视频生成工具

---

## Project Website | 项目网站

Website: [pannotate.art](https://pannotate.art)

Pannotate also has an early web prototype that demonstrates the product concept and workflow.

Pannotate 已经有一个早期网页原型，用于展示产品概念和基本工作流。

---

## Overview | 项目简介

Pannotate is an AI-powered video creation tool that allows users to guide video generation through visual annotations and motion prompts.

Pannotate 是一个面向创作者的 AI 视频生成工具。用户可以从一张图片开始，在图片上进行标注，并通过简短的动作描述来引导 AI 生成视频。

---

## Core Concept | 核心理念

Traditional image-to-video tools rely heavily on text prompts. Pannotate explores a more visual workflow:

传统的图生视频工具主要依赖文字提示词。Pannotate 希望提供一种更直观的工作流：

- Upload an image  
  上传图片

- Annotate directly on the image  
  在图片上直接标注

- Use drawing, circles, text, and directional marks  
  使用画笔、圆圈、文字和方向标记

- Add a motion description  
  添加动作描述

- Generate and organize short video clips  
  生成并整理短视频片段

The goal is to make AI video generation more precise, controllable, and creator-friendly.

目标是让 AI 视频生成更加精准、可控，并更适合创作者使用。

---

## Current Features | 当前功能

This project is currently in the prototype stage.

目前项目处于原型开发阶段。

Implemented:

- Native iOS interface built with SwiftUI  
  使用 SwiftUI 构建的原生 iOS 界面

- Projects screen  
  项目管理页面

- Studio image selection and mock generation flow  
  Studio 图片选择与模拟生成流程

- Outputs screen for generated clips  
  生成结果展示页面

- Sequence screen for arranging clips  
  分镜 / 序列整理页面

- Profile and Settings screens  
  个人资料与设置页面

- Light / Dark / System appearance switching  
  浅色 / 深色 / 跟随系统主题切换

- Local mock interactions  
  本地模拟交互

---

## In Progress | 开发中

Planned or in-progress features:

- Real AI video generation API integration  
  接入真实 AI 视频生成 API

- Annotation tools for drawing, circles, text, and arrows  
  标注工具：画笔、圆圈、文字、箭头

- Clip editing and sequence management  
  视频片段编辑与序列管理

- Project persistence  
  项目数据保存

- Export workflow  
  视频导出流程

- TestFlight internal testing  
  TestFlight 内部测试

---

## Tech Stack | 技术栈

- SwiftUI
- Xcode
- iOS Native Development
- GitHub

---

## Project Status | 项目状态

Pannotate is currently a functional local prototype.  
The current version focuses on UI, user flow, and local mock interactions.

Pannotate 目前是一个可运行的本地原型。当前版本主要聚焦于界面、用户流程和本地模拟交互。

Backend services, real video generation, authentication, payment, and cloud storage are not yet implemented.

后端服务、真实视频生成、登录认证、支付和云端存储尚未接入。

---

## Development Workflow | 开发协作

Recommended workflow:

```bash
main        # stable version
feature/*   # feature development
