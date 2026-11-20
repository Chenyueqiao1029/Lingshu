/*
 * 灵枢轻量 Vault 知识库类型定义
 *
 * 供 VaultManager、MarkdownLinkParser、UI 页面和 WebView 图谱统一使用。
 */
export class VaultFileInfo {
  id: string = '';
  title: string = '';
  filePath: string = '';
  content: string = '';
  createTime: number = 0;
  updateTime: number = 0;
}

export class GraphNode {
  id: string = '';
  title: string = '';
  filePath: string = '';
  content: string = '';
  updateTime: number = 0;
}

export class GraphLink {
  source: string = '';
  target: string = '';
}

export class GraphData {
  nodes: GraphNode[] = [];
  links: GraphLink[] = [];
}

export enum VaultMode {
  PRIVATE_SANDBOX = 0,
  EXTERNAL_URI = 1
}

export enum VaultErrorCode {
  OK = 0,
  DIR_NOT_FOUND = 1,
  PERMISSION_DENIED = 2,
  IO_FAILED = 3,
  PARSE_FAILED = 4,
  NOTE_NOT_FOUND = 5,
  VAULT_NOT_INIT = 6
}

export class VaultResult<T> {
  ok: boolean = true;
  code: VaultErrorCode = VaultErrorCode.OK;
  message: string = '';
  data: T | null = null;
}

export class AgentTextOutput {
  text: string = '';
  suggestedFileName: string = '';
}
