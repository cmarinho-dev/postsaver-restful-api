export type SocialSource =
  | 'INSTAGRAM'
  | 'TIKTOK'
  | 'FACEBOOK'
  | 'KWAI'
  | 'YOUTUBE'
  | 'TWITTER'
  | 'OTHER';

export const SOCIAL_SOURCES: { label: string; value: SocialSource }[] = [
  { label: 'Instagram', value: 'INSTAGRAM' },
  { label: 'TikTok', value: 'TIKTOK' },
  { label: 'Facebook', value: 'FACEBOOK' },
  { label: 'Kwai', value: 'KWAI' },
  { label: 'YouTube', value: 'YOUTUBE' },
  { label: 'Twitter/X', value: 'TWITTER' },
  { label: 'Outro', value: 'OTHER' },
];

export interface Tag {
  id: number;
  name: string;
  color?: string | null;
}

export interface Folder {
  id: number;
  name: string;
  description?: string | null;
  color?: string | null;
  createdAt?: string;
}

export interface Post {
  id: number;
  title: string;
  url: string;
  description?: string | null;
  source: SocialSource;
  thumbnailUrl?: string | null;
  favorite: boolean;
  folder?: Folder | null;
  tags: Tag[];
  createdAt?: string;
  updatedAt?: string;
}

export interface PostRequest {
  title: string;
  url: string;
  description?: string | null;
  source: SocialSource;
  thumbnailUrl?: string | null;
  favorite?: boolean;
  folderId?: number | null;
  tagIds?: number[];
}

export interface Page<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  number: number;
  size: number;
}

export interface PostFilter {
  q?: string;
  source?: SocialSource | null;
  folderId?: number | null;
  tagId?: number | null;
  favorite?: boolean | null;
  page?: number;
  size?: number;
}
