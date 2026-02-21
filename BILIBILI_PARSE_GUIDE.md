# 哔哩哔哩解析接口使用说明

本文档仅提供接口能力与接入方式。

## 1. 能力说明

提供三段能力：

1. 从文本中解析 `BV` 和可选分 P 参数 `p`。
2. 根据 `bvid` 获取视频元数据与对应 `cid`。
3. 根据 `bvid + cid` 获取可播放音频流 URL。

## 2. 推荐调用顺序

1. 解析输入文本：得到 `bvid`、`page`。
2. 调用视频信息接口：得到标题、封面、时长、`cid`。
3. 调用播放地址接口：得到 `audioUrl`。

## 3. 文本解析规则

### 3.1 BV 提取

- 正则：`BV[a-zA-Z0-9]{10}`
- 从输入文本中匹配首个 BV 号。

### 3.2 分 P 提取

- 优先从 URL query 读取 `p`。
- 若未读到，再从整段文本兜底匹配 `?p=xx` 或 `&p=xx`。
- `p` 必须为正整数。

### 3.3 b23 短链

- 匹配：`https?://b23\.tv/[a-zA-Z0-9]+`
- 请求短链，读取 30x 的 `Location` 后继续解析其中 BV/p。

## 4. 接口 1：视频元数据

- Method: `GET`
- URL: `https://api.bilibili.com/x/web-interface/view`
- Query: `bvid=BV...`

示例：

```bash
curl 'https://api.bilibili.com/x/web-interface/view?bvid=BV1xx411c7mD'
```

### 4.1 成功判定

- HTTP 200
- JSON `code == 0`

### 4.2 关键返回字段

- `data.title`：视频标题
- `data.owner.name`：UP 主
- `data.pic`：封面 URL
- `data.duration`：视频总时长（秒）
- `data.cid`：默认分 P 的 cid
- `data.pages[]`：分 P 列表
  - `page`：分 P 页码
  - `cid`：该分 P cid
  - `duration`：该分 P 时长（秒）
  - `part`：该分 P 标题

### 4.3 分 P 选择逻辑（建议）

1. 若传入 `page` 且在有效范围内，使用对应 `pages[page-1]`。
2. 否则优先匹配 `data.cid` 对应分 P。
3. 再兜底使用 `pages[0]`。

## 5. 接口 2：音频流地址

- Method: `GET`
- URL: `https://api.bilibili.com/x/player/playurl`
- Query:
  - `bvid=BV...`
  - `cid=...`
  - `fnval=16`
  - `fnver=0`
  - `fourk=1`

必要请求头：

- `User-Agent: Mozilla/5.0 ...`
- `Referer: https://www.bilibili.com/video/{bvid}`

示例：

```bash
curl 'https://api.bilibili.com/x/player/playurl?bvid=BV1xx411c7mD&cid=123456789&fnval=16&fnver=0&fourk=1' \
  -H 'User-Agent: Mozilla/5.0' \
  -H 'Referer: https://www.bilibili.com/video/BV1xx411c7mD'
```

### 5.1 成功判定

- HTTP 200
- JSON `code == 0`
- `data.dash.audio` 非空

### 5.2 音频 URL 取值

- 推荐直接取：`data.dash.audio[0].baseUrl`

## 6. 统一输出结构（建议）

```json
{
  "bvid": "BVxxxxxxxxxx",
  "page": 1,
  "cid": "123456789",
  "title": "视频标题 - 分P标题",
  "artist": "UP主名称",
  "coverUrl": "https://...",
  "duration": 1800,
  "audioUrl": "https://..."
}
```

## 7. 错误处理建议

1. 未解析出 BV：返回“无法识别 BV 号”。
2. `view` 接口失败：可重试一次，仍失败则返回“获取视频信息失败”。
3. `playurl` 接口失败：返回“获取音频地址失败”。
4. `dash.audio` 为空：返回“无可用音频流”。

## 8. 风险与兼容性

1. B 站接口参数/返回结构可能变更。
2. 未带 `Referer/User-Agent` 可能导致取流失败。
3. 部分内容可能受登录或权限限制。
