<?php

namespace Pkp\SiskaKpi;

use InvalidArgumentException;

/**
 * Parameter yang sama untuk semua endpoint KPI (docs/DESIGN_TEAM_KPI_DASHBOARD.md 10.1-10.2).
 * Array kosong = tanpa filter. Angka selalu dalam scope grup akun integrasi.
 */
final class KpiQuery
{
    /** Pilihan periode di dashboard; 730 = batas histori production (tanpa pembanding). */
    public const ALLOWED_DAYS = [7, 30, 90, 180, 365, 730];

    public const COMPARE_MODES = ['auto', 'previous', 'yoy', 'none'];

    /**
     * @param  int[]  $groupIds
     * @param  int[]  $priorityIds
     * @param  string[]  $channels  mis. email, chat, web, phone, sms
     * @param  string[]  $categories  request, complaint, information, no_category
     */
    public function __construct(
        public readonly int $days = 7,
        public readonly array $groupIds = [],
        public readonly array $priorityIds = [],
        public readonly array $channels = [],
        public readonly array $categories = [],
        public readonly ?string $compare = null,
    ) {
        if (! in_array($days, self::ALLOWED_DAYS, true)) {
            throw new InvalidArgumentException('days harus salah satu dari '.implode(', ', self::ALLOWED_DAYS));
        }
        if ($compare !== null && ! in_array($compare, self::COMPARE_MODES, true)) {
            throw new InvalidArgumentException('compare harus salah satu dari '.implode(', ', self::COMPARE_MODES));
        }
    }

    /** Dari request Laravel: ?days=30&group_ids=2,41&channels=email ... */
    public static function fromArray(array $input): self
    {
        $list = static fn ($v) => array_values(array_filter(array_map('trim', is_array($v) ? $v : explode(',', (string) $v)), 'strlen'));

        return new self(
            days: (int) ($input['days'] ?? 7),
            groupIds: array_map('intval', $list($input['group_ids'] ?? [])),
            priorityIds: array_map('intval', $list($input['priority_ids'] ?? [])),
            channels: $list($input['channels'] ?? []),
            categories: $list($input['categories'] ?? []),
            compare: $input['compare'] ?? null,
        );
    }

    /** Query string untuk Zammad (list dipisah koma). */
    public function toQuery(): array
    {
        return array_filter([
            'days' => $this->days,
            'group_ids' => implode(',', $this->groupIds),
            'priority_ids' => implode(',', $this->priorityIds),
            'channels' => implode(',', $this->channels),
            'categories' => implode(',', $this->categories),
            'compare' => $this->compare,
        ], static fn ($v) => $v !== null && $v !== '');
    }

    public function cacheKey(): string
    {
        return md5(json_encode($this->toQuery()));
    }
}
