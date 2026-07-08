import { Component, OnInit, inject } from '@angular/core';
import { Router } from '@angular/router';
import { ProgressSpinnerModule } from 'primeng/progressspinner';
import { AuthService } from '../../core/auth/auth.service';

/**
 * The actual code-for-token exchange already happened in the app initializer
 * (AuthService.initialize, which runs before routing). By the time this
 * component renders, the tokens are in place -- just redirect onward.
 */
@Component({
  selector: 'app-callback-page',
  standalone: true,
  imports: [ProgressSpinnerModule],
  templateUrl: './callback-page.component.html',
  styleUrl: './auth-page.scss',
})
export class CallbackPageComponent implements OnInit {
  private readonly authService = inject(AuthService);
  private readonly router = inject(Router);

  ngOnInit(): void {
    this.router.navigateByUrl(this.authService.isAuthenticated() ? '/' : '/login');
  }
}
