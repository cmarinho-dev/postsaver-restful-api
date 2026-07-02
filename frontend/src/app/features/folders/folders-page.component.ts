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
import { FolderApiService } from '../../core/api.service';
import { Folder } from '../../core/models';

@Component({
  selector: 'app-folders-page',
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
  templateUrl: './folders-page.component.html',
  styleUrl: '../shared/crud-page.scss',
})
export class FoldersPageComponent implements OnInit {
  private readonly folderApi = inject(FolderApiService);
  private readonly messages = inject(MessageService);
  private readonly confirmation = inject(ConfirmationService);

  folders = signal<Folder[]>([]);
  loading = signal(false);

  dialogVisible = false;
  saving = false;
  editingId: number | null = null;
  form: Partial<Folder> = {};

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.folderApi.findAll().subscribe({
      next: (folders) => {
        this.folders.set(folders);
        this.loading.set(false);
      },
      error: () => {
        this.loading.set(false);
        this.messages.add({ severity: 'error', summary: 'Erro', detail: 'Falha ao carregar pastas.' });
      },
    });
  }

  openCreate(): void {
    this.editingId = null;
    this.form = { color: '#6366f1' };
    this.dialogVisible = true;
  }

  openEdit(folder: Folder): void {
    this.editingId = folder.id;
    this.form = { name: folder.name, description: folder.description, color: folder.color ?? '#6366f1' };
    this.dialogVisible = true;
  }

  save(): void {
    if (!this.form.name?.trim()) {
      this.messages.add({ severity: 'warn', summary: 'Campos obrigatórios', detail: 'Informe o nome da pasta.' });
      return;
    }
    this.saving = true;
    const request$ = this.editingId
      ? this.folderApi.update(this.editingId, this.form)
      : this.folderApi.create(this.form);
    request$.subscribe({
      next: () => {
        this.saving = false;
        this.dialogVisible = false;
        this.messages.add({
          severity: 'success',
          summary: 'Sucesso',
          detail: this.editingId ? 'Pasta atualizada.' : 'Pasta criada.',
        });
        this.load();
      },
      error: (err) => {
        this.saving = false;
        this.messages.add({
          severity: 'error',
          summary: 'Erro',
          detail: err?.error?.message ?? 'Não foi possível salvar a pasta.',
        });
      },
    });
  }

  confirmDelete(folder: Folder): void {
    this.confirmation.confirm({
      message: `Excluir a pasta "${folder.name}"?`,
      header: 'Confirmar exclusão',
      icon: 'pi pi-exclamation-triangle',
      acceptLabel: 'Excluir',
      rejectLabel: 'Cancelar',
      acceptButtonStyleClass: 'p-button-danger',
      accept: () => {
        this.folderApi.delete(folder.id).subscribe({
          next: () => {
            this.messages.add({ severity: 'success', summary: 'Sucesso', detail: 'Pasta excluída.' });
            this.load();
          },
          error: (err) => {
            this.messages.add({
              severity: 'error',
              summary: 'Erro',
              detail: err?.error?.message ?? 'Não foi possível excluir a pasta.',
            });
          },
        });
      },
    });
  }
}
