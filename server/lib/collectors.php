<?php
// 収集元ごとの取得関数。いずれも正規化済みの feed item 配列を返す。
//   ['id','oshi_id','source','title','url','published_at','thumbnail_url']

require_once __DIR__ . '/db.php';

function _fid(string $url): string
{
    return sha1($url);
}

function _dt(?string $raw): string
{
    $ts = $raw ? strtotime($raw) : false;
    return date('Y-m-d H:i:s', $ts !== false ? $ts : time());
}

/** YouTube Data API v3: チャンネルの新着動画/配信。 */
function collect_youtube(array $target, string $apiKey): array
{
    $cid = $target['youtube_channel_id'] ?? '';
    if ($cid === '' || $apiKey === '') {
        return [];
    }
    $url = 'https://www.googleapis.com/youtube/v3/search?' . http_build_query([
        'key'        => $apiKey,
        'channelId'  => $cid,
        'part'       => 'snippet',
        'order'      => 'date',
        'type'       => 'video',
        'maxResults' => 10,
    ]);
    $body = http_get($url);
    if ($body === null) {
        return [];
    }
    $data = json_decode($body, true);
    $out = [];
    foreach ($data['items'] ?? [] as $it) {
        $vid = $it['id']['videoId'] ?? null;
        if (!$vid) {
            continue;
        }
        $link = 'https://www.youtube.com/watch?v=' . $vid;
        $sn = $it['snippet'] ?? [];
        $out[] = [
            'id'            => 'yt_' . $vid,
            'oshi_id'       => $target['oshi_id'],
            'source'        => 'youtube',
            'title'         => $sn['title'] ?? '(無題)',
            'url'           => $link,
            'published_at'  => _dt($sn['publishedAt'] ?? null),
            'thumbnail_url' => $sn['thumbnails']['medium']['url'] ?? null,
        ];
    }
    return $out;
}

/** RSS / Atom フィードのパース。 */
function collect_rss(array $target): array
{
    $out = [];
    foreach ($target['rss_urls'] ?? [] as $feedUrl) {
        $body = http_get($feedUrl);
        if ($body === null) {
            continue;
        }
        $xml = @simplexml_load_string($body);
        if ($xml === false) {
            continue;
        }

        // RSS 2.0
        if (isset($xml->channel->item)) {
            foreach ($xml->channel->item as $item) {
                $link = trim((string) $item->link);
                if ($link === '') {
                    continue;
                }
                $out[] = [
                    'id'            => 'rss_' . _fid($link),
                    'oshi_id'       => $target['oshi_id'],
                    'source'        => 'rss',
                    'title'         => trim((string) $item->title) ?: '(無題)',
                    'url'           => $link,
                    'published_at'  => _dt((string) $item->pubDate),
                    'thumbnail_url' => null,
                ];
            }
            continue;
        }

        // Atom
        if (isset($xml->entry)) {
            foreach ($xml->entry as $entry) {
                $link = '';
                foreach ($entry->link as $l) {
                    if ((string) $l['rel'] === 'alternate' || $link === '') {
                        $link = (string) $l['href'];
                    }
                }
                if ($link === '') {
                    continue;
                }
                $out[] = [
                    'id'            => 'rss_' . _fid($link),
                    'oshi_id'       => $target['oshi_id'],
                    'source'        => 'rss',
                    'title'         => trim((string) $entry->title) ?: '(無題)',
                    'url'           => $link,
                    'published_at'  => _dt((string) ($entry->published ?: $entry->updated)),
                    'thumbnail_url' => null,
                ];
            }
        }
    }
    return $out;
}

/** Google Custom Search: 推し名での新着Web/ニュース。 */
function collect_web(array $target, string $key, string $cx): array
{
    $name = $target['name'] ?? '';
    if ($name === '' || $key === '' || $cx === '') {
        return [];
    }
    $url = 'https://www.googleapis.com/customsearch/v1?' . http_build_query([
        'key'         => $key,
        'cx'          => $cx,
        'q'           => $name,
        'num'         => 10,
        'dateRestrict' => 'd7', // 直近7日
        'sort'        => 'date',
    ]);
    $body = http_get($url);
    if ($body === null) {
        return [];
    }
    $data = json_decode($body, true);
    $out = [];
    foreach ($data['items'] ?? [] as $it) {
        $link = $it['link'] ?? '';
        if ($link === '') {
            continue;
        }
        $thumb = $it['pagemap']['cse_thumbnail'][0]['src'] ?? null;
        $out[] = [
            'id'            => 'web_' . _fid($link),
            'oshi_id'       => $target['oshi_id'],
            'source'        => 'web',
            'title'         => $it['title'] ?? '(無題)',
            'url'           => $link,
            'published_at'  => date('Y-m-d H:i:s'),
            'thumbnail_url' => $thumb,
        ];
    }
    return $out;
}
