import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { CardModule } from 'primeng/card';
import { DialogModule } from 'primeng/dialog';
import { DropdownModule } from 'primeng/dropdown';
import { InputTextModule } from 'primeng/inputtext';
import { TextareaModule } from 'primeng/textarea';
import { MultiSelectModule } from 'primeng/multiselect';
import { PaginatorModule, PaginatorState } from 'primeng/paginator';
import { TagModule } from 'primeng/tag';
import { ToggleButtonModule } from 'primeng/togglebutton';
import { TooltipModule } from 'primeng/tooltip';
import { ConfirmationService, MessageService } from 'primeng/api';
import { FolderApiService, PostApiService, TagApiService } from '../../core/api.service';
import { Folder, Post, PostRequest, SOCIAL_SOURCES, SocialSource, Tag } from '../../core/models';

@Component({
  selector: 'app-posts-page',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ButtonModule,
    CardModule,
    DialogModule,
    DropdownModule,
    InputTextModule,
    TextareaModule,
    MultiSelectModule,
    PaginatorModule,
    TagModule,
    ToggleButtonModule,
    TooltipModule,
  ],
  templateUrl: './posts-page.component.html',
  styleUrl: './posts-page.component.scss',
})
export class PostsPageComponent implements OnInit {
  private readonly postApi = inject(PostApiService);
  private readonly folderApi = inject(FolderApiService);
  private readonly tagApi = inject(TagApiService);
  private readonly messages = inject(MessageService);
  private readonly confirmation = inject(ConfirmationService);

  readonly sources = SOCIAL_SOURCES;

  posts = signal<Post[]>([]);
  folders = signal<Folder[]>([]);
  tags = signal<Tag[]>([]);
  totalRecords = signal(0);
  loading = signal(false);

  q = '';
  filterSource: SocialSource | null = null;
  filterFolderId: number | null = null;
  filterTagId: number | null = null;
  onlyFavorites = false;
  page = 0;
  readonly pageSize = 12;

  dialogVisible = false;
  saving = false;
  editingId: number | null = null;
  form: PostRequest = this.emptyForm();

  ngOnInit(): void {
    this.loadLookups();
    this.loadPosts();
  }

  loadLookups(): void {
    this.folderApi.findAll().subscribe((folders) => this.folders.set(folders));
    this.tagApi.findAll().subscribe((tags) => this.tags.set(tags));
  }

  loadPosts(): void {
    this.loading.set(true);
    this.postApi
      .search({
        q: this.q || undefined,
        source: this.filterSource,
        folderId: this.filterFolderId,
        tagId: this.filterTagId,
        favorite: this.onlyFavorites ? true : null,
        page: this.page,
        size: this.pageSize,
      })
      .subscribe({
        next: (page) => {
          this.posts.set(page.content);
          this.totalRecords.set(page.totalElements);
          this.loading.set(false);
        },
        error: () => {
          this.loading.set(false);
          this.messages.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao carregar posts.' });
        },
      });
  }

  onFilterChange(): void {
    this.page = 0;
    this.loadPosts();
  }

  onPageChange(event: PaginatorState): void {
    this.page = event.page ?? 0;
    this.loadPosts();
  }

  openCreate(): void {
    this.editingId = null;
    this.form = this.emptyForm();
    this.dialogVisible = true;
  }

  openEdit(post: Post): void {
    this.editingId = post.id;
    this.form = {
      title: post.title,
      url: post.url,
      description: post.description,
      source: post.source,
      thumbnailUrl: post.thumbnailUrl,
      favorite: post.favorite,
      folderId: post.folder?.id ?? null,
      tagIds: post.tags.map((t) => t.id),
    };
    this.dialogVisible = true;
  }

  save(): void {
    if (!this.form.title?.trim() || !this.form.url?.trim() || !this.form.source) {
      this.messages.add({
        severity: 'warn',
        summary: 'Campos obrigatórios',
        detail: 'Preencha título, URL e rede social.',
      });
      return;
    }
    this.saving = true;
    const request$ = this.editingId
      ? this.postApi.update(this.editingId, this.form)
      : this.postApi.create(this.form);
    request$.subscribe({
      next: () => {
        this.saving = false;
        this.dialogVisible = false;
        this.messages.add({
          severity: 'success',
          summary: 'Sucesso',
          detail: this.editingId ? 'Post atualizado.' : 'Post salvo.',
        });
        this.loadPosts();
      },
      error: (err) => {
        this.saving = false;
        this.messages.add({
          severity: 'error',
          summary: 'Erro',
          detail: err?.error?.message ?? 'Não foi possível salvar o post.',
        });
      },
    });
  }

  toggleFavorite(post: Post): void {
    this.postApi.toggleFavorite(post.id).subscribe((updated) => {
      this.posts.update((posts) => posts.map((p) => (p.id === updated.id ? updated : p)));
    });
  }

  confirmDelete(post: Post): void {
    this.confirmation.confirm({
      message: `Excluir o post "${post.title}"?`,
      header: 'Confirmar exclusão',
      icon: 'pi pi-exclamation-triangle',
      acceptLabel: 'Excluir',
      rejectLabel: 'Cancelar',
      acceptButtonStyleClass: 'p-button-danger',
      accept: () => {
        this.postApi.delete(post.id).subscribe(() => {
          this.messages.add({ severity: 'success', summary: 'Sucesso', detail: 'Post excluído.' });
          this.loadPosts();
        });
      },
    });
  }

  openLink(post: Post): void {
    window.open(post.url, '_blank', 'noopener');
  }

  sourceLabel(source: SocialSource): string {
    return this.sources.find((s) => s.value === source)?.label ?? source;
  }

  sourceSeverity(source: SocialSource): 'success' | 'info' | 'warn' | 'danger' | 'secondary' | 'contrast' {
    switch (source) {
      case 'INSTAGRAM':
        return 'danger';
      case 'TIKTOK':
        return 'contrast';
      case 'FACEBOOK':
        return 'info';
      case 'KWAI':
        return 'warn';
      case 'YOUTUBE':
        return 'danger';
      default:
        return 'secondary';
    }
  }

  private emptyForm(): PostRequest {
    return {
      title: '',
      url: '',
      description: null,
      source: 'INSTAGRAM',
      thumbnailUrl: null,
      favorite: false,
      folderId: null,
      tagIds: [],
    };
  }
}
