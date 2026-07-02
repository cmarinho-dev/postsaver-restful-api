import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { TableModule } from 'primeng/table';
import { TooltipModule } from 'primeng/tooltip';
import { ColorPickerModule } from 'primeng/colorpicker';
import { ConfirmationService, MessageService } from 'primeng/api';
import { TagApiService } from '../../core/api.service';
import { Tag } from '../../core/models';

@Component({
  selector: 'app-tags-page',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ButtonModule,
    DialogModule,
    InputTextModule,
    TableModule,
    TooltipModule,
    ColorPickerModule,
  ],
  templateUrl: './tags-page.component.html',
  styleUrl: '../shared/crud-page.scss',
})
export class TagsPageComponent implements OnInit {
  private readonly tagApi = inject(TagApiService);
  private readonly messages = inject(MessageService);
  private readonly confirmation = inject(ConfirmationService);

  tags = signal<Tag[]>([]);
  loading = signal(false);

  dialogVisible = false;
  saving = false;
  editingId: number | null = null;
  form: Partial<Tag> = {};

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.tagApi.findAll().subscribe({
      next: (tags) => {
        this.tags.set(tags);
        this.loading.set(false);
      },
      error: () => {
        this.loading.set(false);
        this.messages.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao carregar tags.' });
      },
    });
  }

  openCreate(): void {
    this.editingId = null;
    this.form = { color: '#22c55e' };
    this.dialogVisible = true;
  }

  openEdit(tag: Tag): void {
    this.editingId = tag.id;
    this.form = { name: tag.name, color: tag.color ?? '#22c55e' };
    this.dialogVisible = true;
  }

  save(): void {
    if (!this.form.name?.trim()) {
      this.messages.add({ severity: 'warn', summary: 'Campos obrigatórios', detail: 'Informe o nome da tag.' });
      return;
    }
    this.saving = true;
    const request$ = this.editingId
      ? this.tagApi.update(this.editingId, this.form)
      : this.tagApi.create(this.form);
    request$.subscribe({
      next: () => {
        this.saving = false;
        this.dialogVisible = false;
        this.messages.add({
          severity: 'success',
          summary: 'Sucesso',
          detail: this.editingId ? 'Tag atualizada.' : 'Tag criada.',
        });
        this.load();
      },
      error: (err) => {
        this.saving = false;
        this.messages.add({
          severity: 'error',
          summary: 'Erro',
          detail: err?.error?.message ?? 'Não foi possível salvar a tag.',
        });
      },
    });
  }

  confirmDelete(tag: Tag): void {
    this.confirmation.confirm({
      message: `Excluir a tag "${tag.name}"? Ela será removida de todos os posts.`,
      header: 'Confirmar exclusão',
      icon: 'pi pi-exclamation-triangle',
      acceptLabel: 'Excluir',
      rejectLabel: 'Cancelar',
      acceptButtonStyleClass: 'p-button-danger',
      accept: () => {
        this.tagApi.delete(tag.id).subscribe({
          next: () => {
            this.messages.add({ severity: 'success', summary: 'Sucesso', detail: 'Tag excluída.' });
            this.load();
          },
          error: (err) => {
            this.messages.add({
              severity: 'error',
              summary: 'Erro',
              detail: err?.error?.message ?? 'Não foi possível excluir a tag.',
            });
          },
        });
      },
    });
  }
}
