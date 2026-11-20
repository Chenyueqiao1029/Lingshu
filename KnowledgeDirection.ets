/*
 * 灵枢 · 知识方向（话题方向）分类 —— 多标签、纯本地、零依赖
 *
 * 用途：给「用户个人知识库」的每条笔记打方向标签，支撑双机对比报告里的
 *       「共同关注方向 / 各自侧重 / 方向级重合度」。
 *
 * 口径：
 *   - 多标签：一条笔记可以同时属于 健康医疗 和 学习教育（不像以前单选一个 domain）
 *   - 计分：命中词在**标题**里 +3，在**正文**里 +1（标题更接近"用户问的问题方向"）
 *   - 纯本地零依赖：不调模型、不联网，毫秒级，结果可解释（每个方向带上命中的词）
 *
 * 升级位（先留口子，没启用）：词表没命中/低分的条目，可以交给端侧模型
 *   （ai/NpuProvider.ets 的 chat()）兜底分类 —— 跟 IntentParser 的"规则快路径 + LLM 兜底"同套路。
 *
 * 隐私：方向 key 最多十几个字符，跟着标题一起过链路；正文永远不出端。
 */

/** 一个方向的定义 */
export class DirectionDef {
  key: string = '';
  label: string = '';
  words: string[] = [];

  constructor(key: string, label: string, words: string[]) {
    this.key = key;
    this.label = label;
    this.words = words;
  }
}

/** 一条笔记的单个方向命中 */
export class DirectionHit {
  key: string = '';
  label: string = '';
  score: number = 0;
  /** 命中的词（便于报告/排查解释） */
  words: string = '';
}

/** 旧版本（内置语料时代）的单值 domain → 新方向 key */
function legacyKey(d: string): string {
  if (d === 'elder') { return 'elder'; }
  if (d === 'farm' || d === 'agri') { return 'agro'; }
  if (d === 'barrier_free') { return 'barrier'; }
  return '';
}

const DEFS: DirectionDef[] = [
  new DirectionDef('health', '健康医疗',
    ['健康', '医疗', '医院', '医生', '看病', '吃药', '用药', '药物', '药品', '血压', '血糖', '心率',
      '睡眠', '失眠', '作息', '锻炼', '健身', '跑步', '减肥', '体重', '饮食', '营养', '感冒', '发烧',
      '咳嗽', '头疼', '疼痛', '过敏', '皮肤', '爆痘', '黑头', '体检', '康复', '中医', '养生']),
  new DirectionDef('study', '学习教育',
    ['学习', '复习', '考试', '四级', '六级', '英语', '口语', '单词', '背单词', '课程', '上课', '作业',
      '论文', '考研', '自学', '读书', '笔记', '数学', '物理', '化学', '历史', '地理', '教程', '刷题', '习题']),
  new DirectionDef('tech', '科技AI',
    ['AI', '人工智能', '大模型', '模型', '算法', '编程', '代码', '开发', '软件', '硬件', '芯片', '手机',
      '电脑', '鸿蒙', 'HarmonyOS', '星闪', '神经网络', '机器学习', '深度学习', '技术', '开源',
      '接口', 'API', '部署', '服务器']),
  new DirectionDef('finance', '财务理财',
    ['理财', '投资', '基金', '股票', '存款', '储蓄', '预算', '记账', '省钱', '花销', '开销', '收入',
      '支出', '工资', '报销', '成本', '价格', '性价比', '保险', '房贷', '房租', '财务', '经济', '纳税']),
  new DirectionDef('life', '生活家居',
    ['做饭', '菜谱', '吃什么', '美食', '外卖', '家务', '收纳', '清洁', '打扫', '阳台', '养花', '宠物',
      '购物', '快递', '天气', '气温', '穿衣', '衣服', '家居', '布置', '超市', '买菜']),
  new DirectionDef('travel', '出行交通',
    ['出行', '导航', '地铁', '公交', '打车', '出租车', '高铁', '火车', '航班', '机票', '机场', '路线',
      '堵车', '停车', '充电', '自驾', '骑行', '步行', '换乘', '通勤']),
  new DirectionDef('work', '工作职业',
    ['工作', '上班', '加班', '会议', '汇报', '项目', '简历', '面试', '实习', '职业', '同事', '领导',
      '客户', '需求', '排期', '入职', '离职', '绩效']),
  new DirectionDef('relation', '情感人际',
    ['恋爱', '分手', '表白', '朋友', '家人', '父母', '爸爸', '妈妈', '孩子', '儿女', '相处', '沟通',
      '吵架', '婚姻', '夫妻', '亲戚', '孤独', '社交']),
  new DirectionDef('elder', '养老适老',
    ['养老', '老年', '老人', '适老', '银发', '退休', '独居', '陪护', '敬老', '高龄', '长寿', '照护']),
  new DirectionDef('agro', '农业乡村',
    ['农业', '农作', '种植', '作物', '农田', '田间', '乡村', '土壤', '灌溉', '收成', '大棚', '养殖',
      '农药', '化肥', '种菜', '播种', '收割', '果园', '菜地']),
  new DirectionDef('barrier', '无障碍助残',
    ['无障碍', '盲人', '视障', '听障', '助残', '轮椅', '导盲', '语音播报', '手语', '残疾人']),
  new DirectionDef('mood', '心理情绪',
    ['情绪', '焦虑', '压力', '抑郁', '心情', '烦恼', '开心', '难过', '烦躁', '内耗', '放松', '冥想', '正念']),
  new DirectionDef('fun', '娱乐休闲',
    ['电影', '音乐', '游戏', '追剧', '旅游', '摄影', '唱歌', '综艺', '动漫', '演唱会'])
];

export class KnowledgeDirection {
  /** 方向总数 */
  static count(): number {
    return DEFS.length;
  }

  static labelOf(key: string): string {
    for (let i = 0; i < DEFS.length; i++) {
      if (DEFS[i].key === key) {
        return DEFS[i].label;
      }
    }
    return key;
  }

  /**
   * 多标签分类：标题命中权重 3、正文（前 600 字）命中权重 1。
   * 返回按分数降序排列的全部命中方向（分数 > 0），调用方自己取前 N 个。
   */
  /**
   * 标题归一化：App 自动生成的笔记名（AI总结_<ts>、AI思维导图、灵枢总结-<日期>…）
   * 会把「AI」这类词刷进方向统计，比的是内容方向、不是文件名，所以先剥前缀，
   * 纯时间戳标题视为"无标题"（只剩正文参与计分）。
   */
  static normalizeTitle(t: string): string {
    let s: string = t !== undefined && t !== null ? t : '';
    const prefixes: string[] = ['AI总结_', 'AI总结', 'AI思维导图_', 'AI思维导图', '灵枢总结-', '灵枢日记-', '提问-'];
    for (let i = 0; i < prefixes.length; i++) {
      if (s.indexOf(prefixes[i]) === 0) {
        s = s.substring(prefixes[i].length);
        break;
      }
    }
    let onlyStamp: boolean = s.length > 0;
    for (let i = 0; i < s.length; i++) {
      const ch: string = s.charAt(i);
      if (!((ch >= '0' && ch <= '9') || ch === '_' || ch === '-')) {
        onlyStamp = false;
        break;
      }
    }
    return onlyStamp ? '' : s;
  }

  static classify(title: string, content: string): DirectionHit[] {
    const t: string = KnowledgeDirection.normalizeTitle(title !== undefined && title !== null ? title : '');
    const full: string = content !== undefined && content !== null ? content : '';
    const body: string = full.length > 600 ? full.substring(0, 600) : full;
    const out: DirectionHit[] = [];
    for (let i = 0; i < DEFS.length; i++) {
      const d: DirectionDef = DEFS[i];
      let score: number = 0;
      const hits: string[] = [];
      for (let k = 0; k < d.words.length; k++) {
        const w: string = d.words[k];
        if (t.indexOf(w) >= 0) {
          score += 3;
          hits.push(w);
        }
        if (body.indexOf(w) >= 0) {
          score += 1;
          hits.push(w);
        }
      }
      if (score > 0) {
        const h: DirectionHit = new DirectionHit();
        h.key = d.key;
        h.label = d.label;
        h.score = score;
        h.words = hits.join('/');
        out.push(h);
      }
    }
    out.sort((a: DirectionHit, b: DirectionHit): number => {
      return b.score - a.score;
    });
    return out;
  }

  /** 分类结果的 key 串（存进 KbPoint.domain，跟着报文过链路） */
  static encodeKeys(title: string, content: string): string {
    const hits: DirectionHit[] = KnowledgeDirection.classify(title, content);
    const keys: string[] = [];
    for (let i = 0; i < hits.length; i++) {
      keys.push(hits[i].key);
    }
    return keys.join(',');
  }

  /** 解析 domain 字段：兼容新的逗号多值 / 旧的单值（elder / farm / barrier_free / general） */
  static keysOf(domain: string): string[] {
    const out: string[] = [];
    if (domain === undefined || domain === null || domain === '') {
      return out;
    }
    if (domain.indexOf(',') >= 0) {
      const parts: string[] = domain.split(',');
      for (let i = 0; i < parts.length; i++) {
        if (parts[i] !== '' && out.indexOf(parts[i]) < 0) {
          out.push(parts[i]);
        }
      }
      return out;
    }
    // 单值：先按新 key 认（life / travel / health…），认不出再当旧版单值映射
    if (KnowledgeDirection.isKnownKey(domain)) {
      out.push(domain);
      return out;
    }
    const legacy: string = legacyKey(domain);
    if (legacy !== '') {
      out.push(legacy);
    }
    return out;
  }

  /** 是否是当前词表里的方向 key */
  static isKnownKey(key: string): boolean {
    for (let i = 0; i < DEFS.length; i++) {
      if (DEFS[i].key === key) {
        return true;
      }
    }
    return false;
  }
}
