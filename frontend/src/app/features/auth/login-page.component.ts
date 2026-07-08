import { Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { AuthService } from '../../core/auth/auth.service';

@Component({
  selector: 'app-login-page',
  standalone: true,
  imports: [RouterLink, ButtonModule],
  templateUrl: './login-page.component.html',
  styleUrl: './auth-page.scss',
})
export class LoginPageComponent {
  private readonly authService = inject(AuthService);

  login(): void {
    this.authService.login();
  }
}
