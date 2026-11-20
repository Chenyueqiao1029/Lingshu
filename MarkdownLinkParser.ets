/*
 * 灵枢轻量 Vault - Wiki 双链解析与图谱 JSON 生成
 */
import { GraphNode, GraphLink, GraphData } from './VaultTypes';

export class ParserFileInput {
  id: string = '';
  title: string = '';
  filePath: string = '';
  content: string = '';
  updateTime: number = 0;

  constructor(id: string, title: string, filePath: string, content: string, updateTime: number = 0) {
    this.id = id;
    this.title = title;
    this.filePath = filePath;
    this.content = content;
    this.updateTime = updateTime;
  }
}

export function extractWikiLinks(text: string): string[] {
  const content = (text ?? '').trim();
  if (content === '') {
    return [];
  }
  const links: string[] = [];
  const re: RegExp = /\[\[([^\[\]]+)\]\]/g;
  let m: RegExpExecArray | null = re.exec(content);
  while (m !== null) {
    const raw = m[1].trim();
    const clean = raw.split('|')[0].split('#')[0].trim();
    if (clean !== '' && links.indexOf(clean) < 0) {
      links.push(clean);
    }
    m = re.exec(content);
  }
  return links;
}

export function buildGraphData(files: ParserFileInput[]): GraphData {
  const graph = new GraphData();
  const idByTitle: Map<string, string> = new Map<string, string>();
  for (let i = 0; i < files.length; i++) {
    const f = files[i];
    const node = new GraphNode();
    node.id = f.id;
    node.title = f.title;
    node.filePath = f.filePath;
    node.content = f.content;
    node.updateTime = f.updateTime;
    graph.nodes.push(node);
    if (!idByTitle.has(f.title)) {
      idByTitle.set(f.title, f.id);
    }
  }
  const seen: Set<string> = new Set<string>();
  for (let i = 0; i < files.length; i++) {
    const f = files[i];
    const refs = extractWikiLinks(f.content);
    for (let j = 0; j < refs.length; j++) {
      const targetId = idByTitle.get(refs[j]);
      if (targetId === undefined || targetId === f.id) {
        continue;
      }
      const key = `${f.id}->${targetId}`;
      if (seen.has(key)) {
        continue;
      }
      seen.add(key);
      const link = new GraphLink();
      link.source = f.id;
      link.target = targetId;
      graph.links.push(link);
    }
  }
  return graph;
}

export function graphDataToJson(graph: GraphData): string {
  return JSON.stringify({ nodes: graph.nodes, links: graph.links });
}