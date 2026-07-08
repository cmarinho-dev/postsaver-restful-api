import { Component, inject } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { PasswordModule } from 'primeng/password';
import { MessageService } from 'primeng/api';
import { UserApiService } from '../../core/api.service';
import { UserRequest } from '../../core/models';

@Component({
  selector: 'app-register-page',
  standalone: true,
  imports: [FormsModule, RouterLink, ButtonModule, InputTextModule, PasswordModule],
  templateUrl: './register-page.component.html',
  styleUrl: './auth-page.scss',
})
export class RegisterPageComponent {
  private readonly userApi = inject(UserApiService);
  private readonly messages = inject(MessageService);
  private readonly router = inject(Router);

  saving = false;
  form: Partial<UserRequest> = {};

  register(): void {
    if (!this.form.name?.trim() || !this.form.username?.trim() || !this.form.email?.trim() || !this.form.password) {
      this.messages.add({ severity: 'warn', summary: 'Campos obrigatórios', detail: 'Preencha todos os campos.' });
      return;
    }
    this.saving = true;
    this.userApi.register(this.form as UserRequest).subscribe({
      next: () => {
        this.saving = false;
        this.messages.add({ severity: 'success', summary: 'Conta criada', detail: 'Agora faça login.' });
        this.router.navigateByUrl('/login');
      },
      error: (err) => {
        this.saving = false;
        this.messages.add({
          severity: 'error',
          summary: 'Erro',
          detail: err?.error?.message ?? 'Não foi possível criar a conta.',
        });
      },
    });
  }
}
