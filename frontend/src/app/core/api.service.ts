import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { Folder, Page, Post, PostFilter, PostRequest, Tag } from './models';

const BASE = '/api/v1';

@Injectable({ providedIn: 'root' })
export class PostApiService {
  private readonly http = inject(HttpClient);

  search(filter: PostFilter): Observable<Page<Post>> {
    let params = new HttpParams()
      .set('page', filter.page ?? 0)
      .set('size', filter.size ?? 12)
      .set('sort', 'createdAt,desc');
    if (filter.q) params = params.set('q', filter.q);
    if (filter.source) params = params.set('source', filter.source);
    if (filter.folderId != null) params = params.set('folderId', filter.folderId);
    if (filter.tagId != null) params = params.set('tagId', filter.tagId);
    if (filter.favorite != null) params = params.set('favorite', filter.favorite);
    return this.http.get<Page<Post>>(`${BASE}/posts`, { params });
  }

  create(request: PostRequest): Observable<Post> {
    return this.http.post<Post>(`${BASE}/posts`, request);
  }

  update(id: number, request: PostRequest): Observable<Post> {
    return this.http.put<Post>(`${BASE}/posts/${id}`, request);
  }

  toggleFavorite(id: number): Observable<Post> {
    return this.http.patch<Post>(`${BASE}/posts/${id}/favorite`, {});
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${BASE}/posts/${id}`);
  }
}

@Injectable({ providedIn: 'root' })
export class FolderApiService {
  private readonly http = inject(HttpClient);

  findAll(): Observable<Folder[]> {
    return this.http.get<Folder[]>(`${BASE}/folders`);
  }

  create(request: Partial<Folder>): Observable<Folder> {
    return this.http.post<Folder>(`${BASE}/folders`, request);
  }

  update(id: number, request: Partial<Folder>): Observable<Folder> {
    return this.http.put<Folder>(`${BASE}/folders/${id}`, request);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${BASE}/folders/${id}`);
  }
}

@Injectable({ providedIn: 'root' })
export class TagApiService {
  private readonly http = inject(HttpClient);

  findAll(): Observable<Tag[]> {
    return this.http.get<Tag[]>(`${BASE}/tags`);
  }

  create(request: Partial<Tag>): Observable<Tag> {
    return this.http.post<Tag>(`${BASE}/tags`, request);
  }

  update(id: number, request: Partial<Tag>): Observable<Tag> {
    return this.http.put<Tag>(`${BASE}/tags/${id}`, request);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${BASE}/tags/${id}`);
  }
}
