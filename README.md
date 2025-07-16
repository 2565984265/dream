# 旅行轻指南 - 短途旅行规划平台

> 结合 AI 能力与创作者社区，打造轻量、高效、真实、有趣的短途旅行规划平台。

## 🚀 项目概述

本项目是一个现代化的短途旅行规划平台，采用前后端分离架构，提供智能路线规划、地图服务、社区互动等功能。

### 核心功能

- **🗺️ 智能地图服务**: 基于GSI（地理空间信息）数据的地图展示
- **🤖 AI路线规划**: 智能推荐个性化旅行路线
- **📖 攻略中心**: 用户分享和浏览旅行攻略
- **👥 社区互动**: 创作者经济模式，支持内容分享
- **🎯 多出行方式**: 支持徒步、骑行、摩托、自驾、房车

## 🏗️ 技术架构

### 后端技术栈
- **框架**: Spring Boot 3.5.3 + Java 17
- **数据库**: PostgreSQL + Redis
- **地理数据**: GSI（地理空间信息）存储
- **安全**: Spring Security
- **文档**: SpringDoc OpenAPI
- **其他**: JPA、邮件服务、验证等

### 前端技术栈
- **框架**: Next.js 13.4.19 + React 18.2.0
- **样式**: Tailwind CSS
- **地图**: Leaflet + React-Leaflet
- **图标**: Heroicons
- **语言**: TypeScript

## 📁 项目结构

```
dream/
├── short-trip-background/          # 后端服务
│   ├── src/main/java/org/example/shorttrip/
│   │   ├── controller/             # 控制器层
│   │   ├── service/                # 服务层
│   │   ├── repository/             # 数据访问层
│   │   ├── model/                  # 数据模型
│   │   │   ├── entity/             # 实体类
│   │   │   ├── dto/                # 数据传输对象
│   │   │   └── enums/              # 枚举类
│   │   └── config/                 # 配置类
│   └── src/main/resources/
│       └── application.properties  # 应用配置
├── short-trip-front/               # 前端应用
│   ├── src/
│   │   ├── app/                    # 页面组件
│   │   ├── components/             # 通用组件
│   │   └── types/                  # TypeScript类型定义
│   └── package.json
├── start-backend.sh               # 后端启动脚本
├── start-frontend.sh              # 前端启动脚本
└── README.md
```

## 🗺️ 地图和路线规划引擎

### GSI数据存储

项目实现了完整的地理空间信息（GSI）数据存储系统：

#### 核心实体
- **GSIEntity**: 地理空间信息实体，存储POI数据
- **RouteEntity**: 路线实体，存储路线规划数据

#### 支持的地理数据类型
- **自然景观**: 山峰、湖泊、河流、森林、海滩、瀑布、洞穴
- **人文景观**: 寺庙、博物馆、公园、广场、桥梁、塔楼
- **交通设施**: 车站、机场、港口、公路、道路
- **服务设施**: 酒店、餐厅、商店、医院、学校、银行
- **户外活动**: 露营地、徒步路线、骑行路线、攀岩、钓鱼
- **观景点**: 观景台、日出点、日落点、观星点
- **补给点**: 补给点、水源、加油站、维修点

#### 主要功能
- **区域查询**: 根据经纬度范围查询POI
- **附近搜索**: 根据中心点和半径查找附近POI
- **类型筛选**: 支持按类型筛选POI
- **评分推荐**: 基于评分的POI推荐
- **批量导入**: 支持批量导入GSI数据

### 路线规划引擎

#### 核心功能
- **AI路线生成**: 根据出发地、时间、偏好生成个性化路线
- **路线优化**: 结合创作者真实数据优化推荐路线
- **多出行方式**: 支持徒步、骑行、摩托、自驾、房车
- **难度评估**: 路线难度等级评估
- **时间估算**: 精确的行程时间估算

#### 路线属性
- 出发地和目的地
- 总距离和预计时间
- 难度等级（1-5）
- 途经点信息
- 推荐玩法和注意事项
- 最佳季节和所需装备

## 🚀 快速开始

### 环境要求

- **Java**: 17 或更高版本
- **Node.js**: 16 或更高版本
- **PostgreSQL**: 12 或更高版本
- **Redis**: 6 或更高版本
- **Maven**: 3.6 或更高版本

### 数据库设置

1. 创建PostgreSQL数据库：
```sql
CREATE DATABASE short_trip_db;
```

2. 配置数据库连接（`short-trip-background/src/main/resources/application.properties`）：
```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/short_trip_db
spring.datasource.username=postgres
spring.datasource.password=postgres
```

### 启动服务

#### 方式一：使用启动脚本（推荐）

```bash
# 启动后端服务
./start-backend.sh

# 启动前端服务（新终端）
./start-frontend.sh
```

#### 方式二：手动启动

```bash
# 启动后端
cd short-trip-background
mvn spring-boot:run

# 启动前端（新终端）
cd short-trip-front
npm install
npm run dev
```

### 访问地址

- **前端应用**: http://localhost:3000
- **地图页面**: http://localhost:3000/map
- **API文档**: http://localhost:8080/swagger-ui.html
- **健康检查**: http://localhost:8080/api/health

## 📚 API接口

### GSI数据管理接口

#### 基础CRUD操作
- `POST /api/gsi` - 保存GSI数据
- `GET /api/gsi/{id}` - 根据ID获取GSI数据
- `GET /api/gsi/gsi-id/{gsiId}` - 根据GSI ID获取数据
- `PUT /api/gsi/{gsiId}` - 更新GSI数据
- `DELETE /api/gsi/{gsiId}` - 删除GSI数据

#### 查询接口
- `GET /api/gsi/pois/area` - 根据经纬度范围查找POI
- `GET /api/gsi/pois/nearby` - 查找附近的POI
- `GET /api/gsi/pois/recommended` - 获取推荐POI
- `GET /api/gsi/pois` - 分页查询所有POI
- `GET /api/gsi/pois/type/{type}` - 根据类型分页查询POI
- `GET /api/gsi/pois/stats` - 统计各类型POI数量

#### 批量操作
- `POST /api/gsi/batch` - 批量导入GSI数据
- `PUT /api/gsi/{gsiId}/status` - 启用/禁用GSI

### 路线规划接口

- `POST /api/routes/generate` - 生成推荐路线
- `POST /api/routes/optimize/{routeId}` - 优化推荐路线

### 地图服务接口

- `GET /api/map/pois` - 查询区域兴趣点
- `GET /api/map/routes/{routeId}/layer` - 获取路线图层

## 🗺️ 地图功能使用

### 前端地图组件

地图组件支持以下功能：

#### 基础功能
- 交互式地图展示
- 标记点显示和筛选
- 路线可视化
- 响应式设计

#### POI功能
- **自动加载**: 根据地图视野自动加载POI数据
- **类型筛选**: 支持按类型筛选POI
- **详细信息**: 点击标记查看POI详细信息
- **实时更新**: 地图移动时自动更新POI数据

#### 使用示例

```tsx
import Map from '@/components/Map';

// 基础使用
<Map 
  center={[39.9042, 116.4074]} 
  zoom={12} 
/>

// 启用POI加载
<Map 
  center={[39.9042, 116.4074]} 
  zoom={12}
  enablePOILoading={true}
  selectedPOITypes={['MOUNTAIN', 'LAKE']}
/>
```

### 地图页面功能

访问 http://localhost:3000/map 可以体验完整的地图功能：

- **POI加载开关**: 控制是否自动加载POI数据
- **类型筛选**: 选择要显示的POI类型
- **路线显示**: 显示推荐路线
- **统计信息**: 显示发现的POI数量

## 🔧 开发指南

### 添加新的GSI类型

1. 在 `GSIType` 枚举中添加新类型
2. 在 `POIType` 枚举中添加对应类型
3. 更新类型转换逻辑

### 自定义地图样式

修改 `Map.tsx` 组件中的样式配置：

```tsx
// 自定义标记图标
const customIcon = L.divIcon({
  className: 'custom-marker',
  html: `<div style="background-color: ${iconColor}; ..."></div>`,
  iconSize: [20, 20],
  iconAnchor: [10, 10],
});
```

### 扩展路线规划算法

在 `RoutePlanningServiceImpl` 中实现自定义算法：

```java
@Override
public RoutePlanResponse generateRoute(RoutePlanRequest request) {
    // 实现你的路线规划算法
    // 可以集成第三方地图API或AI服务
}
```

## 🧪 测试数据

项目启动时会自动初始化测试数据，包括：

- **北京地区**: 天安门广场、故宫、颐和园、八达岭长城等
- **杭州地区**: 西湖、灵隐寺、千岛湖等
- **张家界地区**: 张家界国家森林公园、天门山等
- **交通设施**: 火车站、机场等
- **露营点**: 各地露营基地
- **观景台**: 各地观景台

## 📝 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📄 许可证

本项目采用 Apache 2.0 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🤝 联系我们

- 项目主页: [GitHub Repository](https://github.com/your-username/dream)
- 问题反馈: [Issues](https://github.com/your-username/dream/issues)
- 邮箱: support@shorttrip.com

---

**享受你的短途旅行规划之旅！** 🚀🗺️ 